defmodule ArchethicPlaygroundWeb.CreateTransactionComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.TransactionChain.TransactionData.Ownership
  alias Archethic.Contracts.ContractConstants, as: Constants
  alias Archethic.TransactionChain.TransactionData.TokenLedger
  alias Archethic.TransactionChain.TransactionData.TokenLedger.Transfer, as: TokenTransfer
  alias Archethic.TransactionChain.TransactionData.UCOLedger.Transfer, as: UCOTransfer
  alias Archethic.Crypto
  alias Archethic.Utils.Regression.Playbook

  alias Archethic.TransactionChain.{
    Transaction,
    TransactionData,
    TransactionData.Ledger,
    TransactionData.UCOLedger
  }

  def render(assigns) do
    ~H"""
      <div>
        <h2>Create a transaction</h2>
        <.form :let={f} for={:form} phx-submit="create_uco_transfer" phx-target={@myself}>
        <h3>UCO Transfers</h3>
            <%= if length(@uco_transfers) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Amount</th>
                    <th>To</th>
                    <th>X</th>
                </tr>
                </thead>
                <tbody>
                <%= for uco_transfer <- @uco_transfers do %>
                <tr id={uco_transfer.id}>
                <td><%= uco_transfer.amount %></td>
                <td><%= "#{String.slice(uco_transfer.to, 0..5)}..." %></td>
                <td><button href="#" phx-target={@myself} phx-click="delete_uco_transfer" phx-value-id={uco_transfer.id} >Delete</button></td>
                </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="uco-transfer-to">
                To
            </label>
            <%= text_input f, :transfer_uco_to, id: "uco-transfer-to", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="uco-transfer-amount">
                Amount
            </label>
            <%= text_input f, :transfer_uco_amount, id: "uco-transfer-amount", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <%= submit "Create UCO transfer", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
        <hr />
        <.form :let={f} for={:form} phx-submit="create_token_transfer" phx-target={@myself}>
        <h3>Token Transfers</h3>
            <%= if length(@token_transfers) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Amount</th>
                    <th>To</th>
                    <th>Token Address</th>
                    <th>Token Id</th>
                    <th>X</th>
                </tr>
                </thead>
                <tbody>
                <%= for token_transfer <- @token_transfers do %>
                <tr>
                    <td><%= token_transfer.amount %></td>
                    <td><%= "#{String.slice(token_transfer.to, 0..5)}..." %></td>
                    <td><%= "#{String.slice(token_transfer.token_address, 0..5)}..." %></td>
                    <td><%= token_transfer.token_id %></td>
                    <td><button href="#" phx-target={@myself} phx-click="delete_token_transfer" phx-value-id={token_transfer.id} >Delete</button></td>
                </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="token-transfer-to">
                To
            </label>
            <%= text_input f, :transfer_token_to, id: "token-transfer-to", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="token-transfer-amount">
                Amount
            </label>
            <%= text_input f, :transfer_token_amount, id: "token-transfer-amount", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="token-transfer-token-address">
                Token address
            </label>
            <%= text_input f, :transfer_token_address, id: "token-transfer-token-address", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="token-transfer-token-id">
                Token id
            </label>
            <%= text_input f, :transfer_token_id, id: "token-transfer-token-id", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <%= submit "Create Token transfer", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
        <hr />
        <.form :let={f} for={:form} phx-submit="create_recipient" phx-target={@myself}>
        <h3>Recipients</h3>
            <%= if length(@recipients) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Address</th>
                    <th>X</th>
                </tr>
                </thead>
                <tbody>
                <%= for recipient <- @recipients do %>
                <tr>
                    <td><%= recipient.address %></td>
                    <td><button href="#" phx-target={@myself} phx-click="delete_recipient" phx-value-id={recipient.id} >Delete</button></td>
                </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="recipient-address">
                Recipient address
            </label>
            <%= text_input f, :recipient_address, id: "recipient-address", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <%= submit "Create Recipient", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
        <hr />
        <.form :let={f} for={:form} phx-submit="create_ownership" phx-target={@myself} phx-change="change_ownership">
        <h3>Ownerships</h3>
        <%= if length(@ownerships) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Secret</th>
                    <th>Authorization keys</th>
                    <th>X</th>
                </tr>
                </thead>
                <tbody>
                <%= for ownership <- @ownerships do %>
                    <tr>
                    <td>*****</td>
                    <td>
                    <%= for authorization_key <- ownership.authorization_keys do %>
                    <%= "#{String.slice(authorization_key, 0..5)}... " %>
                    <% end %>
                    </td>
                    <td><button href="#" phx-target={@myself} phx-click="delete_ownership" phx-value-id={ownership.id} >Delete</button></td>
                    </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="ownership-secret">
                Secret
            </label>
            <%= password_input f, :secret, id: "ownership-secret", value: @secret, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2">
                Authorization keys
            </label>
            <%= for authorization_key <- @authorization_keys do %>
                <%= text_input f, :authorization_key_address, id: authorization_key.id,  name: "form[authorization_keys][#{authorization_key.id}]", placeholder: "Address", value: authorization_key.address, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <% end %>
            </div>
            <div>
            <button href="#" phx-target={@myself} phx-click="add_authorization_key" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4">
                Add Authorization Key
            </button>
            <button href="#" phx-target={@myself} phx-click="add_storage_nonce_public_key" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4">
                Load storage nonce public key
            </button>
            </div>
            <div>
            <%= submit "Create secret", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
            </div>
        </.form>
        <hr />
        <.form :let={f} for={:form} phx-submit="create_transaction" phx-target={@myself}>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="transaction-type">
                Type
            </label>
            <%= select f, :transaction_type, Archethic.TransactionChain.Transaction.types(), id: "transaction-type", value: :contract, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="transaction-content">
                Content
            </label>
            <%= textarea f, :content, id: "transaction-content", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <%= submit @submit_message, class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
      </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(:uco_transfers, [])
      |> assign(:token_transfers, [])
      |> assign(:recipients, [])
      |> assign(:ownerships, [])
      |> assign(:secret, "")
      |> assign(:authorization_keys, [%{address: "", id: "0"}])

    {:ok, socket}
  end

  def handle_event("delete_uco_transfer", %{"id" => uco_transfer_id}, socket) do
    uco_transfers =
      socket.assigns.uco_transfers
      |> Enum.filter(&(&1.id != uco_transfer_id))

    {:noreply, assign(socket, :uco_transfers, uco_transfers)}
  end

  def handle_event(
        "create_uco_transfer",
        %{
          "form" => %{
            "transfer_uco_amount" => transfer_uco_amount,
            "transfer_uco_to" => transfer_uco_to
          }
        },
        socket
      ) do
    uco_transfer = %{
      to: transfer_uco_to,
      amount: transfer_uco_amount,
      id: get_next_id(socket.assigns.uco_transfers)
    }

    uco_transfers = socket.assigns.uco_transfers
    socket = assign(socket, :uco_transfers, [uco_transfer | uco_transfers])
    {:noreply, socket}
  end

  def handle_event("delete_token_transfer", %{"id" => token_transfer_id}, socket) do
    token_transfers =
      socket.assigns.token_transfers
      |> Enum.filter(&(&1.id != token_transfer_id))

    {:noreply, assign(socket, :token_transfers, token_transfers)}
  end

  def handle_event(
        "create_token_transfer",
        %{
          "form" => %{
            "transfer_token_to" => transfer_token_to,
            "transfer_token_amount" => transfer_token_amount,
            "transfer_token_address" => transfer_token_address,
            "transfer_token_id" => transfer_token_id
          }
        },
        socket
      ) do
    token_transfer = %{
      to: transfer_token_to,
      amount: transfer_token_amount,
      token_id: transfer_token_id,
      token_address: transfer_token_address,
      id: get_next_id(socket.assigns.token_transfers)
    }

    token_transfers = socket.assigns.token_transfers
    {:noreply, assign(socket, :token_transfers, [token_transfer | token_transfers])}
  end

  def handle_event("delete_recipient", %{"id" => recipient_id}, socket) do
    recipients =
      socket.assigns.recipients
      |> Enum.filter(&(&1.id != recipient_id))

    {:noreply, assign(socket, :recipients, recipients)}
  end

  def handle_event(
        "create_recipient",
        %{"form" => %{"recipient_address" => recipient_address}},
        socket
      ) do
    recipient = %{
      address: recipient_address,
      id: get_next_id(socket.assigns.recipients)
    }

    recipients = socket.assigns.recipients
    {:noreply, assign(socket, :recipients, [recipient | recipients])}
  end

  def handle_event("delete_ownership", %{"id" => ownership_id}, socket) do
    ownerships =
      socket.assigns.ownerships
      |> Enum.filter(&(&1.id != ownership_id))

    {:noreply, assign(socket, :ownerships, ownerships)}
  end

  def handle_event("change_ownership", params, socket) do
    %{"form" => %{"secret" => secret, "authorization_keys" => authorization_keys}} = params

    authorization_keys =
      authorization_keys
      |> Enum.map(fn {id, value} ->
        %{address: value, id: id}
      end)

    {:noreply, assign(socket, %{authorization_keys: authorization_keys, secret: secret})}
  end

  def handle_event(
        "create_ownership",
        %{"form" => %{"secret" => secret, "authorization_keys" => authorization_keys}},
        socket
      ) do
    authorization_keys =
      authorization_keys
      |> Enum.map(fn {_key, value} ->
        value
      end)

    ownerships = socket.assigns.ownerships

    ownership = %{
      secret: secret,
      authorization_keys: authorization_keys,
      id: get_next_id(socket.assigns.ownerships)
    }

    new_authorization_keys = [%{address: "", id: "0"}]

    socket =
      assign(socket, %{
        ownerships: [ownership | ownerships],
        authorization_keys: new_authorization_keys,
        secret: ""
      })

    {:noreply, socket}
  end

  def handle_event("add_storage_nonce_public_key", _params, socket) do
    %{host: host, port: port} = URI.parse(socket.assigns.endpoint)

    storage_nonce_public_key =
      Playbook.storage_nonce_public_key(host, port)
      |> Base.encode16()

    last_key = List.last(socket.assigns.authorization_keys)

    {new_storage_nonce_public_key, is_drop_last?} =
      if last_key.address == "" do
        {%{last_key | address: storage_nonce_public_key}, true}
      else
        {%{
           address: storage_nonce_public_key,
           id: get_next_id(socket.assigns.authorization_keys)
         }, false}
      end

    reversed_list =
      socket.assigns.authorization_keys
      |> Enum.reverse()
      |> maybe_drop_last(is_drop_last?)

    reversed_list = [new_storage_nonce_public_key | reversed_list]
    authorization_keys = Enum.reverse(reversed_list)
    {:noreply, assign(socket, :authorization_keys, authorization_keys)}
  end

  def handle_event("add_authorization_key", _params, socket) do
    authorization_key = %{
      address: "",
      id: get_next_id(socket.assigns.authorization_keys)
    }

    authorization_keys = socket.assigns.authorization_keys
    {:noreply, assign(socket, :authorization_keys, authorization_keys ++ [authorization_key])}
  end

  def handle_event("create_transaction", params, socket) do
    ownerships = build_ownerships(socket.assigns.ownerships, socket.assigns.aes_key)
    token_transfers = build_token_transfers(socket.assigns.token_transfers)
    uco_transfers = build_uco_transfers(socket.assigns.uco_transfers)
    recipients = build_recipients(socket.assigns.recipients)

    %{
      "form" => %{
        "content" => content,
        "transaction_type" => type
      }
    } = params

    transaction = %Transaction{
      address: "",
      type: String.to_existing_atom(type),
      data: %TransactionData{
        ownerships: ownerships,
        content: content,
        code: socket.assigns.smart_contract_code,
        ledger: %Ledger{
          token: %TokenLedger{
            transfers: token_transfers
          },
          uco: %UCOLedger{
            transfers: uco_transfers
          }
        },
        recipients: recipients
      }
    }

    send_update(self(), socket.assigns.module_to_update,
      id: socket.assigns.id_to_update,
      transaction_map: Constants.from_transaction(transaction),
      transaction: transaction
    )

    {:noreply, socket}
  end

  defp maybe_drop_last(list, false), do: list
  defp maybe_drop_last(list, true), do: tl(list)

  defp build_ownerships(ownerships, aes_key) do
    secret_key = :crypto.strong_rand_bytes(32)

    Enum.map(ownerships, fn %{authorization_keys: authorization_keys, secret: secret} ->
      keys =
        Enum.reduce(authorization_keys, %{}, fn key, acc ->
          key = Base.decode16!(key, case: :mixed)
          Map.merge(acc, %{key => Crypto.ec_encrypt(secret_key, key)})
        end)

      %Ownership{
        secret: Crypto.aes_encrypt(secret, aes_key),
        authorized_keys: keys
      }
    end)
  end

  defp build_token_transfers(token_transfers) do
    token_transfers
    |> Enum.map(fn token_transfer ->
      {amount, _} = Integer.parse(token_transfer.amount)

      %TokenTransfer{
        amount: amount,
        to: Base.decode16!(token_transfer.to),
        token_address: Base.decode16!(token_transfer.token_address),
        token_id: token_transfer.token_id
      }
    end)
  end

  defp build_uco_transfers(uco_transfers) do
    uco_transfers
    |> Enum.map(fn uco_transfer ->
      {amount, _} = Integer.parse(uco_transfer.amount)

      %UCOTransfer{
        to: Base.decode16!(uco_transfer.to),
        amount: amount
      }
    end)
  end

  defp build_recipients(recipients) do
    recipients
    |> Enum.map(fn recipient ->
      Base.decode16!(recipient)
    end)
  end

  defp get_next_id(items) do
    {max_id, _} =
      items
      |> Enum.map(fn i -> i.id end)
      |> Enum.max(&>=/2, fn -> "0" end)
      |> Integer.parse()

    Integer.to_string(max_id + 1)
  end
end
