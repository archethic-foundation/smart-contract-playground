defmodule ArchethicPlayground do
  @moduledoc """
  Main module to run the functionality needed
  """

  alias Archethic.Contracts
  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.Contract.ActionWithTransaction
  alias Archethic.Contracts.Contract.ActionWithoutTransaction
  alias Archethic.Contracts.Contract.ConditionRejected
  alias Archethic.Contracts.Contract.Failure
  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.Interpreter.Logs
  alias Archethic.Crypto
  alias Archethic.TransactionChain.Transaction
  alias ArchethicPlayground.RecipientForm
  alias ArchethicPlayground.Transaction, as: PlaygroundTransaction
  alias ArchethicPlayground.TriggerForm
  alias ArchethicPlayground.Utils

  require Logger

  @spec parse(PlaygroundTransaction.t()) :: {:ok, Contract.t()} | {:error, String.t()}
  def parse(transaction_contract) do
    transaction_contract
    |> PlaygroundTransaction.add_contract_ownership(
      transaction_contract.seed,
      Crypto.storage_nonce_public_key() |> Base.encode16()
    )
    |> PlaygroundTransaction.to_archethic()
    |> Contracts.from_transaction()
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))
      {:error, "Unexpected error #{inspect(error)}"}
  end

  @spec execute_function(
          contract_tx :: PlaygroundTransaction.t(),
          function_name :: String.t(),
          args_values :: list(any())
        ) ::
          {:ok, result :: any(), logs :: Logs.t()}
          | {:error, reason :: Failure.t()}
  def execute_function(contract_tx, function_name, args_values) do
    {:ok, contract} = parse(contract_tx)
    Contracts.execute_function(contract, function_name, args_values)
  end

  @spec execute(PlaygroundTransaction.t(), TriggerForm.t(), list(Mock.t())) ::
          {:ok, tx :: PlaygroundTransaction.t() | nil}
          | {:error, reason :: Failure.t() | ConditionRejected.t()}
  def execute(transaction_contract, trigger_form, mocks) do
    # run in a task to ensure the process' dictionary is cleaned
    # because interpreter use it (ex: http module)
    Utils.Task.run_function_in_task_with_timeout(
      fn ->
        do_execute(transaction_contract, trigger_form, mocks)
      end,
      5000
    )
  end

  defp do_execute(transaction_contract, trigger_form, mocks) do
    trigger =
      TriggerForm.deserialize_trigger(trigger_form.trigger)
      |> then(fn
        {:transaction, action, args_names} when not is_nil(action) and not is_nil(args_names) ->
          # convert the trigger to archethic format
          # (the opposite of what's done in parse_and_get_triggers/1)
          {:transaction, action, length(args_names)}

        other ->
          other
      end)

    datetime =
      case trigger do
        {:datetime, trigger_datetime} ->
          trigger_datetime

        _ ->
          get_time_now(mocks)
      end

    {maybe_tx, maybe_recipient} =
      case trigger_form.transaction do
        nil ->
          {nil, nil}

        trigger_transaction ->
          tx = PlaygroundTransaction.to_archethic(trigger_transaction)
          recipient = RecipientForm.to_archethic(trigger_form.recipient)

          {tx, recipient}
      end

    ArchethicPlayground.MockFunctions.prepare_mocks(mocks)

    with {:ok, contract} <-
           parse(transaction_contract),
         {:ok, logs_precond} <-
           check_valid_precondition(trigger, contract, maybe_tx, maybe_recipient, datetime),
         {:ok,
          %ActionWithTransaction{
            next_tx: next_tx,
            encoded_state: encoded_state,
            logs: logs_action
          }} <-
           Contracts.execute_trigger(
             trigger,
             contract,
             maybe_tx,
             maybe_recipient,
             time_now: datetime
           ),
         {:ok, logs_postcond} <-
           check_valid_postcondition(contract, next_tx, datetime),
         next_tx <-
           PlaygroundTransaction.from_archethic(
             next_tx,
             encoded_state,
             transaction_contract.seed,
             1 + transaction_contract.index
           ) do
      {:ok, next_tx, logs_precond ++ logs_action ++ logs_postcond}
    else
      {:ok, %ActionWithoutTransaction{logs: logs}} ->
        {:ok, nil, logs}

      {:error, reason = %Failure{}} ->
        {:error, reason}

      {:error, reason = %ConditionRejected{}} ->
        {:error, reason}

      {:error, reason} ->
        {:error,
         %Failure{
           user_friendly_error: "Parsing error: #{reason}",
           error: reason,
           logs: [],
           stacktrace: []
         }}
    end
  end

  defp get_time_now(mocks) do
    case(
      Enum.find(mocks, fn
        %{function: "Time.now/0"} -> true
        _ -> false
      end)
    ) do
      nil ->
        DateTime.utc_now()

      mock ->
        mock.output
    end
  end

  defp check_valid_precondition(
         :oracle,
         contract = %Contract{},
         tx = %Transaction{},
         nil,
         datetime
       ) do
    Contracts.execute_condition(:oracle, contract, tx, nil, datetime)
  end

  defp check_valid_precondition(
         condition_type = {:transaction, _, _},
         contract = %Contract{},
         tx = %Transaction{},
         recipient,
         datetime
       ) do
    Contracts.execute_condition(condition_type, contract, tx, recipient, datetime)
  end

  defp check_valid_precondition(_, _, _, _, _), do: {:ok, []}

  defp check_valid_postcondition(
         contract = %Contract{},
         next_tx = %Transaction{},
         datetime
       ) do
    Contracts.execute_condition(:inherit, contract, next_tx, nil, datetime)
  end

  defp check_valid_postcondition(_, _, _), do: {:ok, []}
end
