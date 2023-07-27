defmodule ArchethicPlayground do
  @moduledoc """
  Main module to run the functionality needed
  """
  alias Archethic.Contracts
  alias Archethic.Contracts.Contract
  alias Archethic.TransactionChain.Transaction

  alias ArchethicPlayground.Transaction, as: PlaygroundTransaction
  alias ArchethicPlayground.TriggerForm

  require Logger

  @spec parse(PlaygroundTransaction.t()) :: {:ok, Contract.t()} | {:error, String.t()}
  def parse(transaction_contract) do
    transaction_contract
    |> PlaygroundTransaction.to_archethic()
    |> Contracts.from_transaction()
  rescue
    error ->
      Logger.error(Exception.format(:error, error, __STACKTRACE__))
      {:error, "Unexpected error #{inspect(error)}"}
  end

  @spec execute(PlaygroundTransaction.t(), TriggerForm.t()) ::
          {:ok, PlaygroundTransaction.t() | nil} | {:error, atom()}
  def execute(transaction_contract, trigger_form) do
    trigger = deserialize_trigger(trigger_form.trigger)

    datetime =
      case trigger do
        {:datetime, trigger_datetime} ->
          trigger_datetime

        _ ->
          get_time_now(trigger_form.mocks)
      end

    maybe_tx =
      case trigger_form.transaction do
        nil -> nil
        trigger_transaction -> PlaygroundTransaction.to_archethic(trigger_transaction)
      end

    ArchethicPlayground.MockFunctions.prepare_mocks(trigger_form.mocks)

    with {:ok, contract} <- parse(transaction_contract),
         :ok <- check_valid_precondition(trigger, contract, maybe_tx, datetime),
         {:ok, tx_or_nil} <-
           Contracts.execute_trigger(trigger, contract, maybe_tx, time_now: datetime),
         :ok <- check_valid_postcondition(contract, tx_or_nil, datetime),
         tx_or_nil <- PlaygroundTransaction.from_archethic(tx_or_nil) do
      {:ok, tx_or_nil}
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
        case Integer.parse(mock.output) do
          {int, ""} ->
            DateTime.from_unix!(int)

          _ ->
            send(
              self(),
              {:console, :warning, "Invalid Time.now/0 value, using current time instead."}
            )

            DateTime.utc_now()
        end
    end
  end

  defp deserialize_trigger("oracle"), do: :oracle
  defp deserialize_trigger("transaction"), do: :transaction

  defp deserialize_trigger(trigger_str) do
    [key, rest] = String.split(trigger_str, ":")

    case key do
      "interval" ->
        {:interval, rest}

      "datetime" ->
        {:datetime,
         rest
         |> String.to_integer()
         |> DateTime.from_unix!()}
    end
  end

  defp check_valid_precondition(
         :oracle,
         contract = %Contract{},
         tx = %Transaction{},
         datetime
       ) do
    if Contracts.valid_condition?(:oracle, contract, tx, datetime) do
      :ok
    else
      {:error, :invalid_oracle_constraints}
    end
  end

  defp check_valid_precondition(
         :transaction,
         contract = %Contract{},
         tx = %Transaction{},
         datetime
       ) do
    if Contracts.valid_condition?(:transaction, contract, tx, datetime) do
      :ok
    else
      {:error, :invalid_transaction_constraints}
    end
  end

  defp check_valid_precondition(_, _, _, _), do: :ok

  defp check_valid_postcondition(
         contract = %Contract{},
         next_tx = %Transaction{},
         datetime
       ) do
    if Contracts.valid_condition?(:inherit, contract, next_tx, datetime) do
      :ok
    else
      {:error, :invalid_inherit_constraints}
    end
  end

  defp check_valid_postcondition(_, _, _), do: :ok
end
