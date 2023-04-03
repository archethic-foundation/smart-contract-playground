defmodule ArchethicPlaygroundWeb.TriggerComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.ContractConstants, as: Constants
  alias Archethic.Contracts.Interpreter
  alias ArchethicPlaygroundWeb.CreateTransactionComponent

  alias Archethic.TransactionChain.{
    Transaction,
    TransactionData
  }

  def render(assigns) do
    ~H"""
      <div class={if @is_show_trigger == true, do: "flex flex-col h-4/4 py-2 min-w-[350px]", else: "hidden" }>
        <h2 class="text-lg font-medium text-gray-400 ml-4">Select a trigger</h2>
        <div class="relative mt-2 flex-1 px-2 sm:px-2">
            <div class="absolute inset-0 px-2 sm:px-2">
                <div class="h-full border-2 border border-gray-500 bg-black text-gray-200 p-4 overflow-y-auto">
                    <div class="block">
                        <.form :let={f} for={%{}} as={:form} phx-submit="execute_action" phx-change="update_form" phx-target={@myself} class="w-full max-w-lg">
                            <div class="flex flex-wrap -mx-3 mb-6">
                            <div class="w-full px-3">
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="triggers">
                                Select the action you want to trigger
                                </label>
                                <%= select f, :trigger, @triggers, value: @selected_trigger, id: "triggers", prompt: "Select a trigger", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
                            </div>

                            <%= if @display_oracle_form do %>
                                <div class="w-full px-3">
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="oracle-content">
                                    Oracle content
                                </label>
                                <%= text_input f, :oracle_content, id: "oracle-content", required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                                </div>
                            <% end %>
                            </div>
                            <%= unless @display_transaction_form do %>
                              <%= submit "Trigger", disabled: @selected_trigger == "", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" %>
                            <% end %>
                        </.form>
                        <%= if @display_transaction_form do %>
                          <.live_component module={CreateTransactionComponent} id="create-transaction-trigger" module_to_update={__MODULE__} id_to_update="trigger_component" smart_contract_code={@smart_contract_code} aes_key={@aes_key} />
                          <div class="mt-5">
                            <a phx-click="execute_transaction" phx-target={@myself} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" href="#">
                              Trigger
                            </a>
                          </div>
                        <% end %>
                    </div>
                </div>
            </div>
        </div>
      </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(:display_transaction_form, false)
      |> assign(:display_oracle_form, false)
      |> assign(:selected_trigger, "")
      |> assign(:transaction, nil)
      |> assign(:aes_key, :crypto.strong_rand_bytes(32))

    {:ok, socket}
  end

  def handle_event("update_form", params, socket) do
    trigger_form = params["form"]["trigger"]
    display_transaction_form = trigger_form == "transaction"
    display_oracle_form = trigger_form == "oracle"

    socket =
      socket
      |> assign(:display_transaction_form, display_transaction_form)
      |> assign(:display_oracle_form, display_oracle_form)
      |> assign(:selected_trigger, trigger_form)

    {:noreply, socket}
  end

  def handle_event("execute_action", %{"form" => %{"trigger" => trigger_form}}, socket) do
    trigger =
      case trigger_form do
        "oracle" ->
          :oracle

        "transaction" ->
          :transaction

        key_with_param ->
          key_with_param
          |> String.split(":")
          |> case do
            ["interval", value] ->
              {:interval, value}

            ["datetime", value] ->
              {value, _} = Integer.parse(value)
              {:datetime, DateTime.from_unix!(value)}
          end
      end

    execute_contract(trigger, socket.assigns.interpreted_contract, nil)

    {:noreply, socket}
  end

  def handle_event("execute_transaction", _transaction_form, socket) do
    # FIXME: transaction_form is always %{}
    # FIXME: here we should convert the transaction_form into a %Transaction{} and feed it as 3rd argument
    execute_contract(:transaction, socket.assigns.interpreted_contract, nil)
    {:noreply, socket}
  end

  def update(%{transaction_map: transaction}, socket) do
    socket = assign(socket, transaction: transaction)
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp execute_contract(trigger, contract, maybe_tx) do
    # IMPROVE: trigger_transaction, is a map that is `inspect` into the console
    case Interpreter.execute(trigger, contract, maybe_tx) do
      {:ok, tx_or_nil} ->
        send(self(), {:trigger_transaction, %{"success" => tx_or_nil}})

      {:error, reason} ->
        send(self(), {:trigger_transaction, %{"error" => reason}})
    end
  end
end
