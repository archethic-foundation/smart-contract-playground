defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false

  alias ArchethicPlayground.Transaction
  alias ArchethicPlayground.TriggerForm
  alias ArchethicPlaygroundWeb.ConsoleComponent
  alias ArchethicPlaygroundWeb.ContractComponent
  alias ArchethicPlaygroundWeb.DeployComponent
  alias ArchethicPlaygroundWeb.FunctionComponent
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent
  alias ArchethicPlaygroundWeb.TriggerComponent

  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.Contract.ConditionRejected
  alias Archethic.Contracts.Contract.Failure

  use ArchethicPlaygroundWeb, :live_view

  def mount(_params, _opts, socket) do
    code = default_code()

    socket =
      socket
      |> assign(
        # ui related
        left_panel: nil,
        right_panel: "contract",
        console_messages: [],
        # contract related
        triggers: [],
        functions: [],
        transaction_contract:
          Transaction.new(%{
            "type" => "contract",
            "code" => code
          })
          |> Ecto.Changeset.apply_changes()
      )
      |> push_event("set-code", %{"code" => code})

    # do a first parse in order to fill the triggers
    send(self(), {:parse, code})

    {:ok, socket}
  end

  def handle_event("toggle_panel", %{"panel" => panel, "side" => side}, socket) do
    {left_panel, right_panel} =
      do_toggle_panels({side, panel}, {socket.assigns.left_panel, socket.assigns.right_panel})

    socket =
      socket
      |> assign(left_panel: left_panel, right_panel: right_panel)
      |> push_event("resize-editor", %{})

    {:noreply, socket}
  end

  def handle_event("parse", %{"code" => code}, socket) do
    send(self(), {:parse, code})
    {:noreply, socket}
  end

  def handle_info({:console, :clear}, socket) do
    {:noreply, assign(socket, console_messages: [])}
  end

  def handle_info({:console, :logs, logs}, socket) do
    dated_data =
      logs
      |> Enum.uniq()
      |> Enum.map(fn {datetime, term} ->
        {datetime, :info, inspect(term)}
      end)

    {:noreply, assign(socket, console_messages: socket.assigns.console_messages ++ dated_data)}
  end

  def handle_info({:console, class, data}, socket) do
    dated_data = {DateTime.utc_now(), class, data}
    {:noreply, assign(socket, console_messages: socket.assigns.console_messages ++ [dated_data])}
  end

  def handle_info({:parse, code}, socket) do
    send(self(), {:console, :clear})

    transaction_contract = %Transaction{socket.assigns.transaction_contract | code: code}

    {triggers, functions} =
      case ArchethicPlayground.parse(transaction_contract) do
        {:ok, contract} ->
          {get_triggers(contract), get_public_functions(contract)}

        {:error, message} ->
          send(self(), {:console, :error, message})
          {[], []}
      end

    # maybe it'd be good to store the contract as well

    {:noreply,
     socket
     |> assign(
       triggers: triggers,
       functions: functions,
       transaction_contract: transaction_contract
     )}
  end

  def handle_info(:reset_transaction_contract, socket) do
    code = socket.assigns.transaction_contract.code

    transaction_contract =
      Transaction.new(%{"type" => "contract", "code" => code})
      |> Ecto.Changeset.apply_changes()

    {:noreply, assign(socket, :transaction_contract, transaction_contract)}
  end

  def handle_info({:set_transaction_contract, transaction}, socket) do
    {:noreply, assign(socket, :transaction_contract, transaction)}
  end

  def handle_info({:execute_function, function_name, args_values}, socket) do
    send(self(), {:console, :clear})
    send(self(), {:console, :info, "Executing function: #{function_name}/#{length(args_values)}"})

    case ArchethicPlayground.execute_function(
           socket.assigns.transaction_contract,
           function_name,
           args_values
         ) do
      {:ok, value, logs} ->
        send(self(), {:console, :logs, logs})
        send(self(), {:console, :success, value})

      {:error, %Failure{user_friendly_error: err, logs: logs}} ->
        send(self(), {:console, :logs, logs})
        send(self(), {:console, :error, err})
    end

    {:noreply, socket}
  end

  def handle_info({:execute_trigger, trigger_form, mocks, replace_contract?}, socket) do
    send(self(), {:console, :clear})
    send(self(), {:console, :info, "Executing trigger: #{trigger_form.trigger}"})

    socket =
      case ArchethicPlayground.execute(
             socket.assigns.transaction_contract,
             trigger_form,
             mocks
           ) do
        {:ok, nil, logs} ->
          send(self(), {:console, :logs, logs})
          send(self(), {:console, :success, "No resulting transaction"})
          socket

        {:ok, tx, logs} ->
          send(self(), {:console, :logs, logs})

          send(
            self(),
            {:console, :success,
             Transaction.to_short_map(tx,
               filter_code: tx.code == socket.assigns.transaction_contract.code
             )}
          )

          if replace_contract? do
            socket
            |> assign(transaction_contract: tx)
            |> push_event("set-code", %{"code" => tx.code})
          else
            socket
          end

        {:error, %Failure{user_friendly_error: reason, logs: logs}} ->
          send(self(), {:console, :logs, logs})
          send(self(), {:console, :error, reason})
          socket

        {:error, %ConditionRejected{subject: subject, reason: reason, logs: logs}} ->
          send(self(), {:console, :logs, logs})
          send(self(), {:console, :error, condition_rejected_to_string(subject, reason)})
          socket
      end

    {:noreply, socket}
  end

  #              _            _
  #   _ __  _ __(___   ____ _| |_ ___
  #  | '_ \| '__| \ \ / / _` | __/ _ \
  #  | |_) | |  | |\ V | (_| | ||  __/
  #  | .__/|_|  |_| \_/ \__,_|\__\___|
  #  |_|

  defp condition_rejected_to_string("N/A", nil),
    do: "Condition rejected"

  defp condition_rejected_to_string("N/A", reason),
    do: "Condition rejected: #{reason}"

  defp condition_rejected_to_string(subject, nil),
    do: "Condition '#{subject}' rejected"

  defp condition_rejected_to_string(subject, reason),
    do: "Condition '#{subject}' rejected: #{reason}"

  defp get_triggers(%Contract{triggers: triggers}) do
    triggers
    |> Enum.map(fn
      {{:transaction, action, arity}, %{args: args_names}}
      when not is_nil(action) and not is_nil(arity) ->
        # we replace the arity by args_names to be able to put labels on the inputs
        {:transaction, action, args_names}

      {trigger_key, _} ->
        trigger_key
    end)
    |> Enum.map(&TriggerForm.serialize_trigger/1)
  end

  defp get_public_functions(%Contract{functions: functions}) do
    functions
    |> Enum.reduce([], fn
      {{name, _arity}, %{args: args_names, visibility: :public}}, acc ->
        [{name, args_names} | acc]

      _, acc ->
        acc
    end)
  end

  defp do_toggle_panels({"left", panel}, {current_left_panel, current_right_panel}) do
    left_panel = if panel == current_left_panel, do: nil, else: panel
    {left_panel, current_right_panel}
  end

  defp do_toggle_panels({"right", panel}, {current_left_panel, current_right_panel}) do
    right_panel = if panel == current_right_panel, do: nil, else: panel
    {current_left_panel, right_panel}
  end

  defp default_code(),
    do: ~S"""
    @version 1

    condition triggered_by: transaction, as: []
    actions triggered_by: transaction do
      Contract.set_content "Hello world!"
    end
    """
end
