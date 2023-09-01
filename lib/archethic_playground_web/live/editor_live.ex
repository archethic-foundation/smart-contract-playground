defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false

  alias ArchethicPlayground.Utils
  alias ArchethicPlayground.Transaction
  alias ArchethicPlayground.TriggerForm
  alias ArchethicPlaygroundWeb.ConsoleComponent
  alias ArchethicPlaygroundWeb.ContractComponent
  alias ArchethicPlaygroundWeb.DeployComponent
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent
  alias ArchethicPlaygroundWeb.TriggerComponent

  use ArchethicPlaygroundWeb, :live_view

  def mount(_params, _opts, socket) do
    code = default_code()

    # we define a random address so we can prefill the trigger transaction recipients
    random_address = Utils.Address.random() |> Base.encode16()

    socket =
      socket
      |> assign(
        # ui related
        left_panel: nil,
        right_panel: "contract",
        console_messages: [],
        # contract related
        triggers: [],
        transaction_contract:
          Transaction.new(%{
            "address" => random_address,
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

  def handle_info({:console, class, data}, socket) do
    dated_data = {DateTime.utc_now(), class, data}
    {:noreply, assign(socket, console_messages: socket.assigns.console_messages ++ [dated_data])}
  end

  def handle_info({:parse, code}, socket) do
    send(self(), {:console, :clear})

    transaction_contract = %Transaction{socket.assigns.transaction_contract | code: code}

    triggers =
      case parse_and_get_triggers(transaction_contract) do
        {:ok, triggers} ->
          triggers

        {:error, message} ->
          send(self(), {:console, :error, message})
          []
      end

    socket =
      socket
      |> assign(triggers: triggers, transaction_contract: transaction_contract)

    {:noreply, socket}
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

  def handle_info({:execute_contract, trigger_form, mocks, replace_contract?}, socket) do
    send(self(), {:console, :clear})
    send(self(), {:console, :info, "Executing trigger: #{trigger_form.trigger}"})

    socket =
      case ArchethicPlayground.execute(
             socket.assigns.transaction_contract,
             trigger_form,
             mocks
           ) do
        {:ok, nil} ->
          send(self(), {:console, :success, "No resulting transaction"})
          socket

        {:ok, tx} ->
          send(
            self(),
            {:console, :success,
             Transaction.to_short_map(tx,
               filter_code: tx.code == socket.assigns.transaction_contract.code
             )}
          )

          if replace_contract? do
            # hack:
            # we give the transaction the same address as previous so we can chain without having to
            # update the recipients on the trigger form
            tx = %Transaction{tx | address: socket.assigns.transaction_contract.address}

            socket
            |> assign(transaction_contract: tx)
            |> push_event("set-code", %{"code" => tx.code})
          else
            socket
          end

        {:error, :invalid_transaction_constraints} ->
          send(self(), {:console, :error, "Contract's condition 'transaction' failed"})
          socket

        {:error, :invalid_inherit_constraints} ->
          send(self(), {:console, :error, "Contract's condition 'inherit' failed"})
          socket

        {:error, :invalid_oracle_constraints} ->
          send(self(), {:console, :error, "Contract's condition 'oracle' failed"})
          socket

        {:error, :invalid_triggers_execution} ->
          send(self(), {:console, :error, "Trigger is incorrect"})
          socket

        {:error, :contract_failure} ->
          send(self(), {:console, :error, "Contract's execution failed"})
          socket

        {:error, :recipient_not_found_in_trigger_transaction} ->
          send(
            self(),
            {:console, :error,
             "Matching recipient not found in the trigger transaction (left panel)"}
          )

          socket

        {:error, message} when is_binary(message) ->
          send(self(), {:console, :error, message})
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

  defp parse_and_get_triggers(code) do
    case ArchethicPlayground.parse(code) do
      {:ok, %Archethic.Contracts.Contract{triggers: triggers}} ->
        triggers_as_string =
          triggers
          |> Map.keys()
          |> Enum.map(&TriggerForm.serialize_trigger/1)

        {:ok, triggers_as_string}

      {:error, message} ->
        {:error, message}
    end
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

    condition transaction: []
    actions triggered_by: transaction do
      Contract.set_content("Hello world!")
    end
    """
end
