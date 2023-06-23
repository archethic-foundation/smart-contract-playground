defmodule ArchethicPlaygroundWeb.DeployComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.Crypto
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
                        <.form :let={f} for={%{}} as={:form} phx-target={@myself} phx-change="update_selected_network" class="w-full max-w-lg">
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
                          </div>
                        </.form>
                        <.live_component module={CreateTransactionComponent} id="create-transaction-deploy" module_to_update={__MODULE__} id_to_update="deploy_component" smart_contract_code={@smart_contract_code} endpoint={@endpoint} aes_key={@aes_key}/>
                        <hr />
                        <.form :let={f} for={%{}} as={:form} phx-submit="deploy_transaction" phx-target={@myself} phx-change="update_deploy" class="w-full max-w-lg">
                          <div class="flex flex-wrap -mx-3 mb-6">
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
                              <%= inspect(@error_message) %>
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
    mainnet_allowed? =
      :archethic_playground
      |> Application.get_env(__MODULE__, [])
      |> Keyword.get(:mainnet_allowed)

    networks_list = [
      Local: "http://localhost:4000",
      Testnet: "https://testnet.archethic.net",
      Mainnet: "https://mainnet.archethic.net",
      "Custom network": "custom_network"
    ]

    networks_list = if mainnet_allowed?, do: networks_list, else: List.delete_at(networks_list, 2)

    socket =
      socket
      |> assign(:aes_key, :crypto.strong_rand_bytes(32))
      |> assign(:transaction, %{})
      |> assign(:new_transaction_url, nil)
      |> assign(:error_message, nil)
      |> assign(:endpoint, "")
      |> assign(:selected_network, "")
      |> assign(:seed, "")
      |> assign(
        :networks_list,
        networks_list
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
        %{"form" => %{"seed" => seed}},
        socket
      ) do
    endpoint = socket.assigns.endpoint
    %{host: host, port: port, scheme: scheme} = URI.parse(endpoint)
    proto = String.to_existing_atom(scheme)

    socket =
      with true <-
             validate_ownerships(
               socket.assigns.transaction.data.ownerships,
               seed,
               host,
               port,
               proto,
               socket.assigns.aes_key
             ),
           {:ok, new_transaction_address} <-
             deploy(
               socket.assigns.transaction,
               seed,
               host,
               port,
               :ed25519,
               proto
             ) do
        new_transaction_address = Base.encode16(new_transaction_address)
        new_transaction_url = "#{endpoint}/explorer/transaction/#{new_transaction_address}"
        assign(socket, %{new_transaction_url: new_transaction_url, error_message: nil})
      else
        false ->
          assign(socket, %{
            new_transaction_url: nil,
            error_message:
              "You need to create an ownership with the transaction seed as secret and authorize node public key to let nodes generate new transaction from your smart contract"
          })

        {:error, reason} ->
          assign(socket, %{new_transaction_url: nil, error_message: reason})
      end

    {:noreply, socket}
  end

  def handle_event("update_endpoint", new_endpoint_url, socket) do
    {:noreply, assign(socket, :endpoint, new_endpoint_url)}
  end

  def handle_event("update_deploy", params, socket) do
    %{"form" => %{"seed" => seed}} = params

    {:noreply, assign(socket, %{seed: seed})}
  end

  def handle_event("update_selected_network", params, socket) do
    %{"form" => %{"endpoint" => endpoint, "selected_network" => selected_network}} = params

    {:noreply, assign(socket, %{endpoint: endpoint, selected_network: selected_network})}
  end

  defp validate_ownerships([], _, _, _, _, _), do: true

  defp validate_ownerships(ownerships, seed, host, port, proto, aes_key) do
    storage_nonce_public_key = Playbook.storage_nonce_public_key(host, port, proto)

    result =
      Enum.find(ownerships, fn o ->
        {:ok, decrypted_secret} = Crypto.aes_decrypt(o.secret, aes_key)

        if decrypted_secret == seed do
          result = contains_storage_nonce_public_key?(o.authorized_keys, storage_nonce_public_key)

          not is_nil(result)
        else
          false
        end
      end)

    not is_nil(result)
  end

  defp contains_storage_nonce_public_key?(authorized_keys, storage_nonce_public_key) do
    authorized_keys
    |> Map.keys()
    |> Enum.find(fn k -> k == storage_nonce_public_key end)
  end

  defp deploy(
         transaction,
         seed,
         host,
         port,
         curve,
         proto
       ) do
    Playbook.send_transaction_with_await_replication(
      seed,
      transaction.type,
      transaction.data,
      host,
      port,
      curve,
      proto
    )
  end
end
