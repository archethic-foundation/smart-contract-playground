defmodule ArchethicPlaygroundWeb.DeployComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component
  alias ArchethicPlayground.Utils
  alias ArchethicPlayground.Transaction
  alias ArchethicPlayground.RemoteData
  alias Archethic.Utils.Regression.Api

  def id(), do: "deploy_component"

  alias Archethic.TransactionChain.Transaction, as: ArchethicTransaction
  alias Archethic.TransactionChain.TransactionData
  alias Archethic.TransactionChain.TransactionData.Ledger
  alias Archethic.TransactionChain.TransactionData.TokenLedger
  alias Archethic.TransactionChain.TransactionData.TokenLedger.Transfer, as: TokenTransfer
  alias Archethic.TransactionChain.TransactionData.Ownership
  alias Archethic.TransactionChain.TransactionData.UCOLedger
  alias Archethic.TransactionChain.TransactionData.UCOLedger.Transfer, as: UCOTransfer

  @default_wallet_url "ws://localhost:12345"

  def mount(socket) do
    endpoints = list_endpoints()
    default_endpoint = List.first(endpoints)

    form = %{
      "seed" => "",
      "endpoint" => default_endpoint,
      "wallet_url" => @default_wallet_url,
      "deploy_with_wallet" => false
    }

    endpoint = URI.parse(default_endpoint) |> uri_to_api_endpoint()

    socket =
      socket
      |> assign(
        storage_nonce_pubkey: "",
        endpoints: endpoints,
        fees: %RemoteData{},
        deploy: %RemoteData{},
        wallet_connection_state: "Wallet disconnected"
      )

    update_storage_nonce_public_key(endpoint)

    {:ok, assign_form(socket, form)}
  end

  def update(assigns, socket) do
    transaction_changed? =
      Map.has_key?(socket.assigns, :transaction) &&
        Map.has_key?(assigns, :transaction) &&
        assigns.transaction != socket.assigns.transaction

    storage_nonce_changed? =
      Map.has_key?(assigns, :storage_nonce_pubkey) &&
        assigns.storage_nonce_pubkey != socket.assigns.storage_nonce_pubkey

    socket =
      if transaction_changed? || storage_nonce_changed? do
        # reset estimate & deploy
        assign(socket, Map.merge(assigns, %{fees: %RemoteData{}, deploy: %RemoteData{}}))
      else
        assign(socket, assigns)
      end

    {:ok, socket}
  end

  def handle_event("on-form-change", params, socket) do
    if params["_target"] == ["endpoint"] do
      URI.parse(params["endpoint"])
      |> uri_to_api_endpoint()
      |> update_storage_nonce_public_key()
    end

    params =
      if params["wallet_url"] == nil do
        Map.put(params, "wallet_url", @default_wallet_url)
      else
        params
      end

    {:noreply, assign_form(socket, params)}
  end

  def handle_event("estimate", _, socket) do
    uri = URI.parse(socket.assigns.form.source["endpoint"])
    seed = socket.assigns.form.source["seed"]
    storage_nonce_pubkey = socket.assigns.storage_nonce_pubkey

    # todo the storage nonce must be fetch before

    transaction =
      socket.assigns.transaction
      |> Transaction.add_contract_ownership(seed, storage_nonce_pubkey)
      |> Transaction.to_archethic()

    liveview_pid = self()

    Task.Supervisor.start_child(
      ArchethicPlaygroundWeb.TaskSupervisor,
      fn ->
        fees = get_transaction_fees(seed, transaction, uri)
        send_update(liveview_pid, __MODULE__, id: "deploy_component", fees: fees)
      end
    )

    socket = socket |> assign(fees: RemoteData.loading())

    {:noreply, socket}
  end

  def handle_event("deploy", _, socket) do
    uri = URI.parse(socket.assigns.form.source["endpoint"])
    seed = socket.assigns.form.source["seed"]
    storage_nonce_pubkey = socket.assigns.storage_nonce_pubkey

    # todo the storage nonce must be fetch before

    transaction =
      socket.assigns.transaction
      |> Transaction.add_contract_ownership(seed, storage_nonce_pubkey)
      |> Transaction.to_archethic()

    liveview_pid = self()

    Task.Supervisor.start_child(
      ArchethicPlaygroundWeb.TaskSupervisor,
      fn ->
        deploy = send_transaction(seed, transaction, uri)
        send_update(liveview_pid, __MODULE__, id: "deploy_component", deploy: deploy)
      end
    )

    socket = socket |> assign(deploy: RemoteData.loading())
    {:noreply, socket}
  end

  def handle_event("deploy_with_wallet", _, socket) do
    wallet_url = socket.assigns.form.source["wallet_url"]

    transaction =
      socket.assigns.transaction
      |> Transaction.to_archethic()
      |> tx_to_json()

    socket = socket |> assign(deploy: RemoteData.loading())

    {:noreply,
     push_event(socket, "deploy_with_wallet", %{transaction: transaction, wallet_url: wallet_url})}
  end

  def handle_event("wallet_connection_state_change", %{"state" => state}, socket) do
    {:noreply, assign(socket, wallet_connection_state: state)}
  end

  def handle_event("wallet_deployment_error", %{"result" => result}, socket) do
    socket = socket |> assign(deploy: %RemoteData{status: {:failure, result}})
    {:noreply, socket}
  end

  def handle_event("wallet_deployment_success", %{"result" => result}, socket) do
    uri = URI.parse(socket.assigns.form.source["endpoint"])

    success_message =
      %URI{uri | path: "/explorer/transaction/" <> result["transactionAddress"]}
      |> URI.to_string()
      |> RemoteData.success()

    socket = socket |> assign(deploy: success_message)
    {:noreply, socket}
  end

  defp update_storage_nonce_public_key(endpoint) do
    liveview_pid = self()

    Task.Supervisor.start_child(
      ArchethicPlaygroundWeb.TaskSupervisor,
      fn ->
        storage_nonce_pubkey = storage_nonce_public_key(endpoint)

        send_update(liveview_pid, __MODULE__,
          id: "deploy_component",
          storage_nonce_pubkey: storage_nonce_pubkey
        )
      end
    )
  end

  defp storage_nonce_public_key(endpoint) do
    Api.get_storage_nonce_public_key(endpoint) |> Base.encode16()
  end

  defp get_transaction_fees(seed, transaction, uri) do
    case Api.get_transaction_fee(
           seed,
           transaction.type,
           transaction.data,
           uri_to_api_endpoint(uri)
         ) do
      {:ok, %{"fee" => uco, "rates" => %{"eur" => eur_rate, "usd" => usd_rate}}} ->
        RemoteData.success(%{
          uco:
            uco
            |> Archethic.Utils.from_bigint()
            |> Float.round(3),
          eur:
            uco
            |> Kernel.*(eur_rate)
            |> trunc()
            |> Archethic.Utils.from_bigint()
            |> Float.round(3),
          usd:
            uco
            |> Kernel.*(usd_rate)
            |> trunc()
            |> Archethic.Utils.from_bigint()
            |> Float.round(3)
        })

      {:error, reason} ->
        RemoteData.failure(reason)
    end
  end

  defp send_transaction(seed, transaction, uri) do
    case Api.send_transaction_with_await_replication(
           seed,
           transaction.type,
           transaction.data,
           uri_to_api_endpoint(uri),
           await_timeout: 15_000
         ) do
      {:ok, address} ->
        %URI{uri | path: "/explorer/transaction/" <> Base.encode16(address)}
        |> URI.to_string()
        |> RemoteData.success()

      {:error, reason} ->
        RemoteData.failure(reason)
    end
  end

  defp assign_form(socket, form) do
    assign(socket, form: to_form(form))
  end

  defp scheme_to_proto("http"), do: :http
  defp scheme_to_proto("https"), do: :https

  defp list_endpoints() do
    conf = Application.get_env(:archethic_playground, __MODULE__, [])

    endpoints = [
      if Keyword.get(conf, :mainnet_allowed) do
        ["https://mainnet.archethic.net"]
      else
        []
      end,
      if Keyword.get(conf, :localnet_allowed) do
        ["http://localhost:4000"]
      else
        []
      end,
      "https://testnet.archethic.net"
    ]

    List.flatten(endpoints)
  end

  defp destination(form) do
    seed = form.source["seed"]
    endpoint = form.source["endpoint"]

    if seed == "" or is_nil(seed) do
      nil
    else
      # assumption that contract is deployed at index 1 (to be changed later by using chain_length+1)
      contract_address = Utils.Address.from_seed_index(seed, 1)
      genesis_address = Utils.Address.from_seed_index(seed, 0)

      uri = URI.parse(endpoint)
      contract_url = URI.to_string(%URI{uri | path: "/explorer/transaction/#{contract_address}"})
      genesis_url = URI.to_string(%URI{uri | path: "/explorer/transaction/#{genesis_address}"})

      %{
        contract_address: Utils.Format.minify_address(contract_address),
        genesis_address: Utils.Format.minify_address(genesis_address),
        contract_url: contract_url,
        genesis_url: genesis_url
      }
    end
  end

  defp uri_to_api_endpoint(%URI{host: host, port: port, scheme: scheme}) do
    %Api{host: host, port: port, protocol: scheme_to_proto(scheme)}
  end

  defp tx_to_json(%ArchethicTransaction{
         version: version,
         type: type,
         data: %TransactionData{
           ledger: %Ledger{
             uco: %UCOLedger{transfers: uco_transfers},
             token: %TokenLedger{transfers: token_transfers}
           },
           code: code,
           content: content,
           recipients: recipients,
           ownerships: ownerships
         }
       }) do
    %{
      "version" => version,
      "type" => Atom.to_string(type),
      "data" => %{
        "ledger" => %{
          "uco" => %{
            "transfers" =>
              Enum.map(uco_transfers, fn %UCOTransfer{to: to, amount: amount} ->
                %{"to" => Base.encode16(to), "amount" => amount}
              end)
          },
          "token" => %{
            "transfers" =>
              Enum.map(token_transfers, fn %TokenTransfer{
                                             to: to,
                                             amount: amount,
                                             token_address: token_address,
                                             token_id: token_id
                                           } ->
                %{
                  "to" => Base.encode16(to),
                  "amount" => amount,
                  "token" => token_address,
                  "token_id" => token_id
                }
              end)
          }
        },
        "code" => code,
        "content" => Base.encode16(content),
        "recipients" => Enum.map(recipients, &Base.encode16(&1)),
        "ownerships" =>
          Enum.map(ownerships, fn %Ownership{
                                    secret: secret,
                                    authorized_keys: authorized_keys
                                  } ->
            %{
              "secret" => Base.encode16(secret),
              "authorizedKeys" =>
                Enum.map(authorized_keys, fn {public_key, encrypted_secret_key} ->
                  %{
                    "publicKey" => Base.encode16(public_key),
                    "encryptedSecretKey" => Base.encode16(encrypted_secret_key)
                  }
                end)
            }
          end)
      }
    }
  end
end
