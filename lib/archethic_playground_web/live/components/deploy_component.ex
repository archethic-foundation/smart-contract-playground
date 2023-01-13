defmodule ArchethicPlaygroundWeb.DeployComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.Utils.Regression.Playbook
  alias ArchethicPlaygroundWeb.CreateTransactionComponent

  def render(assigns) do
    ~H"""
      <div class={if @is_show_deploy == true, do: "flex flex-col h-4/4 py-2 min-w-[350px]", else: "hidden" }>
        <h2 class="text-lg font-medium text-gray-400 ml-4">Deploy the smart contract</h2>
        <div class="relative mt-2 flex-1 px-2 sm:px-2">
            <div class="absolute inset-0 px-2 sm:px-2">
                <div class="h-full border-2 border border-gray-500 bg-black text-gray-200 p-4 overflow-y-auto">
                    <div class="block">
                        <.live_component module={CreateTransactionComponent} id="create-transaction" module_to_update={__MODULE__} submit_message="Generate transaction" id_to_update="deploy_component" smart_contract_code={@smart_contract_code} />
                        <.form let={f} for={:form} phx-submit="deploy_transaction" phx-target={@myself} phx_change="update_deploy" class="w-full max-w-lg">
                          <div class="flex flex-wrap -mx-3 mb-6">
                            <div class="w-full px-3">
                              <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="selected_network">
                                  Select a network
                              </label>
                              <%= select f, :selected_network, @networks_list, value: @selected_network, id: "selected_network", phx_hook: "hook_SelectNetwork", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
                            </div>
                            <div class="w-full px-3">
                              <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="endpoint">
                                  Endpoint
                              </label>
                              <%= text_input f, :endpoint, value: @endpoint, id: "endpoint", required: true, phx_hook: "hook_UpdateOtherNetwork", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                            </div>

                            <div class="w-full px-3">
                              <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="seed">
                                  Seed
                              </label>
                              <%= password_input f, :seed, value: @seed, id: "seed", required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                            </div>
                            <%= if @transaction == %{}, do: "You first need to generate a transaction" %>
                            <%= submit "Deploy",
                              class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline",
                              disabled: @transaction == %{}
                              %>
                            <%= if not is_nil(@new_transaction_url) do %>
                              Your transaction has been sent to the network. <br />
                              You can verify it <%= link "here", to: @new_transaction_url, target: "_blank" %>
                            <% end %>
                            <%= if not is_nil(@error_message) do %>
                              The transaction has failed: <br />
                              <%= @error_message %>
                            <% end %>
                          </div>
                        </.form>
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
      |> assign(:transaction, %{})
      |> assign(:new_transaction_url, nil)
      |> assign(:error_message, nil)
      |> assign(:endpoint, "")
      |> assign(:selected_network, "")
      |> assign(:seed, "")
      |> assign(:networks_list,
        Local: "http://localhost:4000",
        Testnet: "https://testnet.archethic.net",
        Mainnet: "https://mainnet.archethic.net",
        "Custom network": "custom_network"
      )

    {:ok, socket}
  end

  def update(%{transaction: transaction}, socket) do
    socket = assign(socket, transaction: transaction)
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event(
        "deploy_transaction",
        %{"form" => %{"seed" => seed, "endpoint" => endpoint}},
        socket
      ) do
    %{host: host, port: port} = URI.parse(endpoint)

    socket =
      case deploy(
             socket.assigns.transaction,
             seed,
             host,
             port,
             :ed25519
           ) do
        {:ok, new_transaction_address} ->
          new_transaction_address = Base.encode16(new_transaction_address)
          new_transaction_url = "#{endpoint}/explorer/transaction/#{new_transaction_address}"
          assign(socket, %{new_transaction_url: new_transaction_url, error_message: nil})

        {:error, reason} ->
          assign(socket, %{new_transaction_url: nil, error_message: reason})
      end

    {:noreply, socket}
  end

  def handle_event("update_endpoint", new_endpoint_url, socket) do
    {:noreply, assign(socket, :endpoint, new_endpoint_url)}
  end

  def handle_event("update_deploy", params, socket) do
    %{"form" => %{"seed" => seed, "endpoint" => endpoint, "selected_network" => selected_network}} =
      params

    {:noreply,
     assign(socket, %{seed: seed, endpoint: endpoint, selected_network: selected_network})}
  end

  defp deploy(
         transaction,
         seed,
         host,
         port,
         curve
       ) do
    Playbook.send_transaction_with_await_replication(
      seed,
      transaction.type,
      transaction.data,
      host,
      port,
      curve
    )
  end
end
