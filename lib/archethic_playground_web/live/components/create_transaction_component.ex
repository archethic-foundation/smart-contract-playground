defmodule ArchethicPlaygroundWeb.CreateTransactionComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.TransactionChain.TransactionData.Ownership
  alias Archethic.Contracts.ContractConstants, as: Constants
  alias Archethic.TransactionChain.TransactionData.TokenLedger
  alias Archethic.TransactionChain.TransactionData.TokenLedger.Transfer, as: TokenLedgerTransfer
  alias Archethic.TransactionChain.TransactionData.UCOLedger.Transfer, as: UCOTransfer
  alias Archethic.Crypto
  alias Archethic.Utils.Regression.Playbook

  alias Archethic.TransactionChain.{
    Transaction,
    TransactionData,
    TransactionData.Ledger,
    TransactionData.UCOLedger
  }

  import Ecto.Changeset

  defmodule Recipient do
    @moduledoc false
    alias ArchethicPlaygroundWeb.CreateTransactionComponent
    import Ecto.Changeset
    defstruct [:address]
    @types %{address: :string}
    def changeset(recipient = %__MODULE__{}, attrs) do
      {recipient, @types}
      |> cast(attrs, Map.keys(@types))
      |> validate_required(:address)
      |> CreateTransactionComponent.validate_base_16_address(:address)
    end
  end

  defmodule UcoTransfer do
    @moduledoc false
    alias ArchethicPlaygroundWeb.CreateTransactionComponent
    import Ecto.Changeset
    defstruct [:amount, :to]
    @types %{amount: :float, to: :string}
    def changeset(uco_transfer = %__MODULE__{}, attrs) do
      {uco_transfer, @types}
      |> cast(attrs, Map.keys(@types))
      |> validate_required([:amount, :to])
      |> CreateTransactionComponent.validate_base_16_address(:to)
    end
  end

  defmodule TokenTransfer do
    @moduledoc false
    alias ArchethicPlaygroundWeb.CreateTransactionComponent
    import Ecto.Changeset
    defstruct [:amount, :to, :token_address, :token_id]
    @types %{amount: :float, to: :string, token_address: :string, token_id: :integer}
    def changeset(token_transfer = %__MODULE__{}, attrs) do
      {token_transfer, @types}
      |> cast(attrs, Map.keys(@types))
      |> validate_required([:amount, :to, :token_address, :token_id])
      |> CreateTransactionComponent.validate_base_16_address(:to)
      |> CreateTransactionComponent.validate_base_16_address(:token_address)
    end
  end

  def render(assigns) do
    ~H"""
      <div>
        <h2>Create a transaction</h2>
        <.form :let={f} for={%{}} as={:form} phx-change="change_transaction_info" phx-target={@myself}>
          <div class="w-full px-3">
          <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_transaction-type"}>
              Type
          </label>
          <%= select f, :transaction_type, list_transaction_types(), id: "#{@id_to_update}_transaction-type", value: @transaction_type, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
          </div>
          <div class="w-full px-3">
          <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_transaction-content"}>
              Content
          </label>
          <%= textarea f, :content, id: "#{@id_to_update}_transaction-content", value: @content, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
          </div>
        </.form>
        <hr />
        <.form :let={f} for={@changeset_uco_transfer} phx-submit="create_uco_transfer" phx-change="validate_uco_transfer" phx-target={@myself}>
        <h3>UCO Transfers</h3>
            <%= if length(@uco_transfers) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Amount</th>
                    <th>To</th>
                    <th>Delete</th>
                </tr>
                </thead>
                <tbody>
                <%= for uco_transfer <- @uco_transfers do %>
                <tr id={"#{@id_to_update}_#{uco_transfer.id}"}>
                <td class="text-center"><%= uco_transfer.amount %></td>
                <td class="text-center"><span title={uco_transfer.to}><%= "#{String.slice(uco_transfer.to, 0..5)}..." %></span></td>
                <td class="text-center"><button href="#" phx-target={@myself} phx-click="delete_uco_transfer" phx-value-id={uco_transfer.id} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline">X</button></td>
                </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_uco-transfer-to"}>
                To
            </label>
            <%= text_input f, :to, id: "#{@id_to_update}_uco-transfer-to", required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :to %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_uco-transfer-amount"}>
                Amount
            </label>
            <%= number_input f, :amount, id: "#{@id_to_update}_uco-transfer-amount", step: :any, required: true, min: 0, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :amount %>
            </div>
            <%= submit "Create UCO transfer", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
        <hr />
        <.form :let={f} for={@changeset_token_transfer} phx-submit="create_token_transfer" phx-change="validate_token_transfer" phx-target={@myself}>
        <h3>Token Transfers</h3>
            <%= if length(@token_transfers) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Amount</th>
                    <th>To</th>
                    <th>Token Address</th>
                    <th>Token Id</th>
                    <th>Delete</th>
                </tr>
                </thead>
                <tbody>
                <%= for token_transfer <- @token_transfers do %>
                <tr>
                    <td class="text-center"><%= token_transfer.amount %></td>
                    <td class="text-center"><span title={token_transfer.to}><%= "#{String.slice(token_transfer.to, 0..5)}..." %></span></td>
                    <td class="text-center"><span title={token_transfer.token_address}><%= "#{String.slice(token_transfer.token_address, 0..5)}..." %></span></td>
                    <td class="text-center"><%= token_transfer.token_id %></td>
                    <td class="text-center"><button href="#" phx-target={@myself} phx-click="delete_token_transfer" phx-value-id={token_transfer.id} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline">X</button></td>
                </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_token-transfer-to"}>
                To
            </label>
            <%= text_input f, :to, id: "#{@id_to_update}_token-transfer-to", required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :to %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_token-transfer-amount"}>
                Amount
            </label>
            <%= number_input f, :amount, id: "#{@id_to_update}_token-transfer-amount", step: :any, required: true, min: 0, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :amount %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_token-transfer-token-address"}>
                Token address
            </label>
            <%= text_input f, :token_address, id: "#{@id_to_update}_token-transfer-token-address", required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :token_address %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_token-transfer-token-id"}>
                Token id
            </label>
            <%= number_input f, :token_id, id: "#{@id_to_update}_token-transfer-token-id", required: true, min: 0, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :token_id %>
            </div>
            <%= submit "Create Token transfer", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
        <hr />
        <.form :let={f} for={@changeset_recipient} id={"#{@id_to_update}_recipient"} phx-submit="create_recipient" phx-change="validate_recipient" phx-target={@myself}>
        <h3>Recipients</h3>
            <%= if length(@recipients) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Address</th>
                    <th>Delete</th>
                </tr>
                </thead>
                <tbody>
                <%= for recipient <- @recipients do %>
                <tr>
                  <td class="text-center"><span title={recipient.address}><%= "#{String.slice(recipient.address, 0..10)}..." %></span></td>
                  <td class="text-center"><button href="#" phx-target={@myself} phx-click="delete_recipient" phx-value-id={recipient.id} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline">X</button></td>
                </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_recipient-address"}>
                Recipient address
            </label>
            <%= text_input f, :address, required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <%= error_tag f, :address %>
            </div>
            <%= submit "Create Recipient", class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4" %>
        </.form>
        <hr />
        <.form :let={f} for={%{}} as={:form} phx-submit="create_ownership" phx-target={@myself} phx-change="change_ownership">
        <h3>Ownerships</h3>
        <%= if length(@ownerships) > 0 do %>
            <table class="table-fixed w-full">
                <thead>
                <tr>
                    <th>Secret</th>
                    <th>Authorization keys</th>
                    <th>Delete</th>
                </tr>
                </thead>
                <tbody>
                <%= for ownership <- @ownerships do %>
                    <tr>
                    <td class="text-center">*****</td>
                    <td class="text-center">
                    <%= for authorization_key <- ownership.authorization_keys do %>
                    <span title={authorization_key}><%= "#{String.slice(authorization_key, 0..5)}... " %></span>
                    <% end %>
                    </td>
                    <td class="text-center"><button href="#" phx-target={@myself} phx-click="delete_ownership" phx-value-id={ownership.id} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline">X</button></td>
                    </tr>
                <% end %>
                </tbody>
            </table>
            <% end %>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_ownership-secret"}>
                Secret
            </label>
            <%= password_input f, :secret, id: "#{@id_to_update}_ownership-secret", value: @secret, required: true, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
            <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2">
                Authorization keys
            </label>
            <%= for authorization_key <- @authorization_keys do %>
              <%= text_input f, :authorization_key_address, id: "#{@id_to_update}_auth_key_#{authorization_key.id}", required: true, name: "form[authorization_keys][#{authorization_key.id}]", placeholder: "Address", value: authorization_key.address, class: "appearance-none w-10/12 bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
              <button href="#" disabled={length(@authorization_keys) < 2} phx-target={@myself} phx-click="delete_authorization_key" phx-value-id={authorization_key.id} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline">
                X
              </button>
              <%= if is_invalid_public_key(authorization_key.address) do %>
                This address is invalid
              <% end %>
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
      </div>
    """
  end

  def mount(socket) do
    socket =
      socket
      |> assign(%{
        uco_transfers: [],
        token_transfers: [],
        recipients: [],
        ownerships: [],
        secret: "",
        authorization_keys: [%{address: "", id: "0"}],
        content: "",
        transaction_type: "contract",
        changeset_recipient: Recipient.changeset(%Recipient{}, %{}),
        changeset_uco_transfer: UcoTransfer.changeset(%UcoTransfer{}, %{}),
        changeset_token_transfer: TokenTransfer.changeset(%TokenTransfer{}, %{})
      })

    {:ok, socket}
  end

  def handle_event("delete_uco_transfer", %{"id" => uco_transfer_id}, socket) do
    uco_transfers =
      socket.assigns.uco_transfers
      |> Enum.filter(&(&1.id != uco_transfer_id))

    socket = assign(socket, :uco_transfers, uco_transfers)
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event(
        "create_uco_transfer",
        %{"uco_transfer" => %{"to" => to, "amount" => amount} = uco_transfer},
        socket
      ) do
    changeset_uco_transfer = UcoTransfer.changeset(%UcoTransfer{}, uco_transfer)

    if changeset_uco_transfer.valid? do
      uco_transfer = %{
        to: String.upcase(to),
        amount: amount,
        id: get_next_id(socket.assigns.uco_transfers)
      }

      uco_transfers = socket.assigns.uco_transfers
      socket = assign(socket, :uco_transfers, [uco_transfer | uco_transfers])
      changeset_uco_transfer = UcoTransfer.changeset(%UcoTransfer{}, %{})

      socket =
        assign(socket, %{
          changeset_uco_transfer: changeset_uco_transfer,
          uco_transfers: [uco_transfer | uco_transfers]
        })

      create_transaction(socket)
      {:noreply, socket}
    else
      changeset_uco_transfer = Map.put(changeset_uco_transfer, :action, :insert)
      {:noreply, assign(socket, changeset_uco_transfer: changeset_uco_transfer)}
    end
  end

  def handle_event("validate_uco_transfer", %{"uco_transfer" => uco_transfer}, socket) do
    changeset_uco_transfer =
      %UcoTransfer{}
      |> UcoTransfer.changeset(uco_transfer)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset_uco_transfer: changeset_uco_transfer)}
  end

  def handle_event("delete_token_transfer", %{"id" => token_transfer_id}, socket) do
    token_transfers =
      socket.assigns.token_transfers
      |> Enum.filter(&(&1.id != token_transfer_id))

    socket = assign(socket, :token_transfers, token_transfers)
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event(
        "create_token_transfer",
        %{
          "token_transfer" =>
            %{
              "to" => transfer_token_to,
              "amount" => transfer_token_amount,
              "token_address" => transfer_token_address,
              "token_id" => transfer_token_id
            } = token_transfer
        },
        socket
      ) do
    changeset_token_transfer = TokenTransfer.changeset(%TokenTransfer{}, token_transfer)

    if changeset_token_transfer.valid? do
      token_transfer = %{
        to: String.upcase(transfer_token_to),
        amount: transfer_token_amount,
        token_id: transfer_token_id,
        token_address: String.upcase(transfer_token_address),
        id: get_next_id(socket.assigns.token_transfers)
      }

      token_transfers = socket.assigns.token_transfers
      changeset_token_transfer = TokenTransfer.changeset(%TokenTransfer{}, %{})

      socket =
        assign(socket, %{
          changeset_token_transfer: changeset_token_transfer,
          token_transfers: [token_transfer | token_transfers]
        })

      create_transaction(socket)
      {:noreply, socket}
    else
      changeset_token_transfer = Map.put(changeset_token_transfer, :action, :insert)
      {:noreply, assign(socket, changeset_token_transfer: changeset_token_transfer)}
    end
  end

  def handle_event("validate_token_transfer", %{"token_transfer" => token_transfer}, socket) do
    changeset_token_transfer =
      %TokenTransfer{}
      |> TokenTransfer.changeset(token_transfer)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset_token_transfer: changeset_token_transfer)}
  end

  def handle_event("delete_recipient", %{"id" => recipient_id}, socket) do
    recipients =
      socket.assigns.recipients
      |> Enum.filter(&(&1.id != recipient_id))

    socket = assign(socket, :recipients, recipients)
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event(
        "create_recipient",
        %{"recipient" => %{"address" => recipient_address} = recipient},
        socket
      ) do
    changeset_recipient = Recipient.changeset(%Recipient{}, recipient)

    if changeset_recipient.valid? do
      recipient = %{
        address: String.upcase(recipient_address),
        id: get_next_id(socket.assigns.recipients)
      }

      recipients = socket.assigns.recipients
      changeset_recipient = Recipient.changeset(%Recipient{}, %{})

      socket =
        assign(socket, %{
          changeset_recipient: changeset_recipient,
          recipients: [recipient | recipients]
        })

      create_transaction(socket)
      {:noreply, socket}
    else
      changeset_recipient = Map.put(changeset_recipient, :action, :insert)
      {:noreply, assign(socket, changeset_recipient: changeset_recipient)}
    end
  end

  def handle_event("validate_recipient", %{"recipient" => recipient}, socket) do
    changeset_recipient =
      %Recipient{}
      |> Recipient.changeset(recipient)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset_recipient: changeset_recipient)}
  end

  def handle_event("delete_ownership", %{"id" => ownership_id}, socket) do
    ownerships =
      socket.assigns.ownerships
      |> Enum.filter(&(&1.id != ownership_id))

    socket = assign(socket, :ownerships, ownerships)
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event("delete_authorization_key", %{"id" => authorization_id}, socket) do
    authorization_keys =
      socket.assigns.authorization_keys
      |> Enum.filter(&(&1.id != authorization_id))

    socket = assign(socket, :authorization_keys, authorization_keys)
    create_transaction(socket)
    {:noreply, socket}
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

  def handle_event("change_transaction_info", params, socket) do
    %{"form" => %{"transaction_type" => transaction_type, "content" => content}} = params
    socket = assign(socket, %{transaction_type: transaction_type, content: content})
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event(
        "create_ownership",
        %{"form" => %{"secret" => secret, "authorization_keys" => authorization_keys}},
        socket
      ) do
    # stop if at least one authorization key isn't correct
    socket =
      if Enum.any?(authorization_keys, fn {_key, value} -> is_invalid_public_key(value) end) do
        socket
      else
        authorization_keys =
          authorization_keys
          |> Enum.map(fn {_key, value} ->
            String.upcase(value)
          end)
          |> Enum.reject(&(&1 == ""))

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

        create_transaction(socket)
        socket
      end

    {:noreply, socket}
  end

  def handle_event("add_storage_nonce_public_key", _params, socket) do
    %{host: host, port: port, scheme: scheme} = URI.parse(socket.assigns.endpoint)
    proto = String.to_existing_atom(scheme)

    storage_nonce_public_key =
      Playbook.storage_nonce_public_key(host, port, proto)
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

  defp create_transaction(socket) do
    ownerships = build_ownerships(socket.assigns.ownerships, socket.assigns.aes_key)
    token_transfers = build_token_transfers(socket.assigns.token_transfers)
    uco_transfers = build_uco_transfers(socket.assigns.uco_transfers)
    recipients = build_recipients(socket.assigns.recipients)

    transaction = %Transaction{
      address: "",
      type: String.to_existing_atom(socket.assigns.transaction_type),
      data: %TransactionData{
        ownerships: ownerships,
        content: socket.assigns.content,
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
  end

  def validate_base_16_address(changeset, field) do
    with value <- fetch_field!(changeset, field),
         false <- is_nil(value),
         changeset <- update_change(changeset, field, &String.upcase/1),
         true <- is_invalid_address(value) do
      add_error(changeset, field, "is not a valid address")
    else
      _ -> changeset
    end
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
      {token_id, _} = Integer.parse(token_transfer.token_id)

      %TokenLedgerTransfer{
        amount: amount,
        to: Base.decode16!(token_transfer.to),
        token_address: Base.decode16!(token_transfer.token_address),
        token_id: token_id
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
      Base.decode16!(recipient.address)
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

  defp list_transaction_types() do
    Enum.reject(Archethic.TransactionChain.Transaction.types(), &Transaction.network_type?/1)
  end

  defp is_invalid_address(authorization_key_address) do
    authorization_key_address = String.upcase(authorization_key_address)

    case Base.decode16(authorization_key_address) do
      :error -> true
      {:ok, decoded} -> not Crypto.valid_address?(decoded)
    end
  end

  defp is_invalid_public_key(public_key) do
    public_key = String.upcase(public_key)

    case Base.decode16(public_key) do
      :error -> true
      {:ok, decoded} -> not Crypto.valid_public_key?(decoded)
    end
  end
end
