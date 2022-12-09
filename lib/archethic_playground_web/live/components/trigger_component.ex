defmodule ArchethicPlaygroundWeb.TriggerComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.Contracts.Contract
  alias Archethic.Contracts.ContractConstants, as: Constants
  alias Archethic.Contracts.ActionInterpreter
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
                        <.form let={f} for={:form} phx-submit="execute_action" phx-change="update_form" phx-target={@myself} class="w-full max-w-lg">
                            <div class="flex flex-wrap -mx-3 mb-6">
                            <div class="w-full px-3">
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="triggers">
                                Select the action you want to trigger
                                </label>
                                <%= select f, :trigger, @triggers, value: @selected_trigger, id: "triggers", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
                            </div>

                            <%= if @display_oracle_form do %>
                                <div class="w-full px-3">
                                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="oracle-content">
                                    Oracle content
                                </label>
                                <%= text_input f, :oracle_content, id: "oracle-content", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                                </div>
                            <% end %>
                            </div>
                            <%= unless @display_transaction_form do %>
                            <%= submit "Trigger", disabled: length(@triggers) == 0, class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline" %>
                            <% end %>
                        </.form>
                        <%= if @display_transaction_form do %>
                            <.live_component module={CreateTransactionComponent} id="create-transaction" />
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
      |> assign(:transaction, %{})

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

  def handle_event("execute_action", %{"form" => %{"trigger" => trigger_form}} = params, socket) do
    trigger_transaction =
      trigger_form
      |> case do
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
      |> execute_contract(%{contract: socket.assigns.interpreted_contract}, params, socket)

    send(self(), {:trigger_transaction, trigger_transaction})
    {:noreply, socket}
  end

  def update(%{transaction: transaction}, socket) do
    socket = assign(socket, transaction: transaction)

    trigger_transaction =
      execute_contract(
        :transaction,
        %{contract: socket.assigns.interpreted_contract},
        nil,
        socket
      )

    send(self(), {:trigger_transaction, trigger_transaction})
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def execute_contract(
        {trigger_type, _} = type,
        %{
          contract: %Contract{
            triggers: triggers,
            constants: %Constants{
              contract: contract_constants
            }
          }
        },
        _params,
        _socket
      )
      when trigger_type == :datetime or trigger_type == :interval do
    constants = %{
      "contract" => contract_constants
    }

    ActionInterpreter.execute(Map.fetch!(triggers, type), constants)
  end

  def execute_contract(
        :oracle,
        %{
          contract: %Contract{
            triggers: triggers,
            constants: %Constants{
              contract: contract_constants
            }
          }
        },
        %{"form" => %{"oracle_content" => oracle_content}},
        _socket
      ) do
    transaction =
      Constants.from_transaction(%Transaction{
        address: "",
        type: :oracle,
        data: %TransactionData{
          content: oracle_content
        }
      })

    constants = %{
      "contract" => contract_constants,
      "transaction" => transaction
    }

    ActionInterpreter.execute(Map.fetch!(triggers, :oracle), constants)
  end

  def execute_contract(
        :transaction,
        %{
          contract: %Contract{
            triggers: triggers,
            constants: %Constants{
              # contract: contract_constants
            }
          }
        },
        _params,
        socket
      ) do
    # needed to provide at least one contract address
    recipient_address =
      <<50, 101, 204, 215, 140, 215, 73, 132, 250, 179, 204, 105, 132, 211, 12, 140, 130, 4, 78,
        187, 171, 26, 79, 255, 182, 131, 189, 178, 216, 197, 188, 249>>

    constants = %{
      # "contract" => contract_constants,
      "contract" => %{
        "address" => recipient_address
      },
      "transaction" => socket.assigns.transaction
    }

    ActionInterpreter.execute(Map.fetch!(triggers, :transaction), constants)
  end
end
