defmodule ArchethicPlaygroundWeb.CreateTransactionComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias Archethic.Utils
  alias Archethic.TransactionChain.TransactionData.Ownership
  alias Archethic.TransactionChain.TransactionData.TokenLedger
  alias Archethic.TransactionChain.TransactionData.TokenLedger.Transfer, as: TokenLedgerTransfer
  alias Archethic.TransactionChain.TransactionData.UCOLedger.Transfer, as: UCOTransfer
  alias Archethic.TransactionChain.Transaction.ValidationStamp
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
        <button href="#" phx-target={@myself} phx-click="clear_transaction" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4">
            Clear transaction
        </button>
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
          <div class="w-full px-3">
            <label class="block uppercase tracking-wide text-xs font-bold mb-2" for={"#{@id_to_update}_transaction-code"}>
                Code
            </label>
            <%= if @display_code_block do %>
            <%= textarea f, :code, id: "#{@id_to_update}_transaction-code", value: @code, class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            <% else %>
            The code corresponding to this transaction is the code in the editor
            <% end %>
          </div>
          <%= if @display_mock_values_input do %>
            <div class="w-full px-3">
                MOCK VALUES
                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="validation_timestamp-input">
                  Validation Timestamp
                </label>
                <%= datetime_local_input f, :validation_timestamp, value: @validation_timestamp, step: "1", id: "validation_timestamp-input", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500"  %>
                <label class="block uppercase tracking-wide text-xs font-bold mb-2" for="contract_address-input">
                  Contract's address
                </label>
                <%= text_input f, :contract_address, id: "contract_address-input", class: "appearance-none block w-full bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
            </div>
          <% end %>
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
                    <%= for authorized_key <- ownership.authorized_keys do %>
                    <span title={authorized_key}><%= "#{String.slice(authorized_key, 0..5)}... " %></span>
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
            <%= for authorized_key <- @authorized_keys do %>
              <%= text_input f, :authorized_key_address, id: "#{@id_to_update}_auth_key_#{authorized_key.id}", required: true, name: "form[authorized_keys][#{authorized_key.id}]", placeholder: "Address", value: authorized_key.address, class: "appearance-none w-10/12 bg-gray-200 text-gray-700 border border-gray-200 rounded py-3 px-4 mb-3 leading-tight focus:outline-none focus:bg-white focus:border-gray-500" %>
              <button href="#" disabled={length(@authorized_keys) < 2} phx-target={@myself} phx-click="delete_authorized_key" phx-value-id={authorized_key.id} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded focus:outline-none focus:shadow-outline">
                X
              </button>
              <%= if is_invalid_public_key(authorized_key.address) do %>
                This address is invalid
              <% end %>
            <% end %>
            </div>
            <div>
            <button href="#" phx-target={@myself} phx-click="add_authorized_key" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline m-4">
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
    {:ok, set_default_values(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      if Map.has_key?(assigns, :input_transaction) and assigns.input_transaction != nil do
        uco_transfers =
          assigns.input_transaction.data.ledger.uco.transfers
          |> Enum.with_index()
          |> Enum.map(fn {transfer, index} ->
            %{
              to: Base.encode16(transfer.to),
              amount: Utils.from_bigint(transfer.amount) |> Float.to_string(),
              id: Integer.to_string(index)
            }
          end)

        token_transfers =
          assigns.input_transaction.data.ledger.token.transfers
          |> Enum.with_index()
          |> Enum.map(fn {transfer, index} ->
            %{
              to: Base.encode16(transfer.to),
              amount: Utils.from_bigint(transfer.amount) |> Float.to_string(),
              token_id: Integer.to_string(transfer.token_id),
              token_address: Base.encode16(transfer.token_address),
              id: Integer.to_string(index)
            }
          end)

        ownerships =
          assigns.input_transaction.data.ownerships
          |> Enum.with_index()
          |> Enum.map(fn {ownership, index} ->
            %{
              id: Integer.to_string(index),
              secret: ownership.secret,
              authorized_keys:
                ownership.authorized_keys
                |> Enum.map(fn {authorized_key, _} ->
                  Base.encode16(authorized_key)
                end)
            }
          end)

        transaction =
          socket.assigns.input_transaction
          |> set_validation_stamp(socket)

        send_update(self(), socket.assigns.module_to_update,
          id: socket.assigns.id_to_update,
          component_id: socket.assigns.id,
          transaction: transaction
        )

        assign(
          socket,
          uco_transfers: uco_transfers,
          token_transfers: token_transfers,
          recipients: assigns.input_transaction.data.recipients,
          ownerships: ownerships,
          content: assigns.input_transaction.data.content,
          code: assigns.input_transaction.data.code,
          transaction_type: to_string(assigns.input_transaction.type)
        )
      else
        socket
      end

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

  def handle_event("delete_authorized_key", %{"id" => authorization_id}, socket) do
    authorized_keys =
      socket.assigns.authorized_keys
      |> Enum.filter(&(&1.id != authorization_id))

    socket = assign(socket, :authorized_keys, authorized_keys)
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event("change_ownership", params, socket) do
    %{"form" => %{"secret" => secret, "authorized_keys" => authorized_keys}} = params

    authorized_keys =
      authorized_keys
      |> Enum.map(fn {id, value} ->
        %{address: value, id: id}
      end)

    {:noreply, assign(socket, %{authorized_keys: authorized_keys, secret: secret})}
  end

  def handle_event("change_transaction_info", params, socket) do
    %{"form" => %{"transaction_type" => transaction_type, "content" => content}} = params

    socket =
      if socket.assigns.display_mock_values_input do
        %{
          "form" => %{
            "validation_timestamp" => validation_timestamp,
            "contract_address" => contract_address
          }
        } = params

        # needed because when using keyboard navigation when filling the datefield
        # the data is sent before the seconds can be set
        validation_timestamp =
          case Regex.match?(~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/u, validation_timestamp) do
            true ->
              "#{validation_timestamp}:00"

            false ->
              validation_timestamp
          end

        assign(socket, %{
          validation_timestamp: validation_timestamp,
          contract_address: contract_address
        })
      else
        socket
      end

    socket = assign(socket, %{transaction_type: transaction_type, content: content})
    create_transaction(socket)
    {:noreply, socket}
  end

  def handle_event(
        "create_ownership",
        %{"form" => %{"secret" => secret, "authorized_keys" => authorized_keys}},
        socket
      ) do
    # stop if at least one authorization key isn't correct
    socket =
      if Enum.any?(authorized_keys, fn {_key, value} -> is_invalid_public_key(value) end) do
        socket
      else
        authorized_keys =
          authorized_keys
          |> Enum.map(fn {_key, value} ->
            String.upcase(value)
          end)
          |> Enum.reject(&(&1 == ""))

        ownerships = socket.assigns.ownerships

        ownership = %{
          secret: secret,
          authorized_keys: authorized_keys,
          id: get_next_id(socket.assigns.ownerships)
        }

        new_authorized_keys = [%{address: "", id: "0"}]

        socket =
          assign(socket, %{
            ownerships: [ownership | ownerships],
            authorized_keys: new_authorized_keys,
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

    last_key = List.last(socket.assigns.authorized_keys)

    {new_storage_nonce_public_key, is_drop_last?} =
      if last_key.address == "" do
        {%{last_key | address: storage_nonce_public_key}, true}
      else
        {%{
           address: storage_nonce_public_key,
           id: get_next_id(socket.assigns.authorized_keys)
         }, false}
      end

    reversed_list =
      socket.assigns.authorized_keys
      |> Enum.reverse()
      |> maybe_drop_last(is_drop_last?)

    reversed_list = [new_storage_nonce_public_key | reversed_list]
    authorized_keys = Enum.reverse(reversed_list)
    {:noreply, assign(socket, :authorized_keys, authorized_keys)}
  end

  def handle_event("add_authorized_key", _params, socket) do
    authorized_key = %{
      address: "",
      id: get_next_id(socket.assigns.authorized_keys)
    }

    authorized_keys = socket.assigns.authorized_keys
    {:noreply, assign(socket, :authorized_keys, authorized_keys ++ [authorized_key])}
  end

  def handle_event("clear_transaction", _, socket) do
    send_update(self(), socket.assigns.module_to_update,
      id: socket.assigns.id_to_update,
      component_id: socket.assigns.id,
      transaction: nil
    )

    {:noreply, set_default_values(socket)}
  end

  defp create_transaction(socket) do
    ownerships = build_ownerships(socket.assigns.ownerships, socket.assigns.aes_key)
    token_transfers = build_token_transfers(socket.assigns.token_transfers)
    uco_transfers = build_uco_transfers(socket.assigns.uco_transfers)
    recipients = build_recipients(socket.assigns.recipients)

    code =
      if Map.has_key?(socket.assigns, :smart_contract) do
        socket.assigns.smart_contract_code
      else
        socket.assigns.code
      end

    transaction = %Transaction{
      address: "",
      type: String.to_existing_atom(socket.assigns.transaction_type),
      data: %TransactionData{
        ownerships: ownerships,
        content: socket.assigns.content,
        code: code,
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

    transaction =
      transaction
      |> set_validation_stamp(socket)
      |> set_contract_address(socket)

    send_update(self(), socket.assigns.module_to_update,
      id: socket.assigns.id_to_update,
      component_id: socket.assigns.id,
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

  defp set_validation_stamp(transaction, socket) do
    if socket.assigns.display_mock_values_input do
      validation_timestamp =
        with true <- socket.assigns.validation_timestamp != "",
             {:ok, validation_timestamp_date, _} <-
               DateTime.from_iso8601("#{socket.assigns.validation_timestamp}Z") do
          validation_timestamp_date
        else
          _ ->
            DateTime.utc_now()
        end

      Map.put(transaction, :validation_stamp, %ValidationStamp{timestamp: validation_timestamp})
    else
      transaction
    end
  end

  defp set_contract_address(transaction, socket) do
    if socket.assigns.display_mock_values_input and
         socket.assigns.contract_address != "" and
         not is_invalid_address(socket.assigns.contract_address) do
      Map.put(transaction, :address, Base.decode16!(socket.assigns.contract_address))
    else
      transaction
    end
  end

  defp maybe_drop_last(list, false), do: list
  defp maybe_drop_last(list, true), do: tl(list)

  defp build_ownerships(ownerships, aes_key) do
    secret_key = :crypto.strong_rand_bytes(32)

    Enum.map(ownerships, fn %{authorized_keys: authorized_keys, secret: secret} ->
      keys =
        Enum.reduce(authorized_keys, %{}, fn key, acc ->
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

  defp is_invalid_address(authorized_key_address) do
    authorized_key_address = String.upcase(authorized_key_address)

    case Base.decode16(authorized_key_address) do
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

  defp set_default_values(socket) do
    default_validation_timestamp =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> NaiveDateTime.to_iso8601()

    assign(socket, %{
      uco_transfers: [],
      token_transfers: [],
      recipients: [],
      ownerships: [],
      secret: "",
      authorized_keys: [%{address: "", id: "0"}],
      content: "",
      code: "",
      transaction_type: "contract",
      changeset_recipient: Recipient.changeset(%Recipient{}, %{}),
      changeset_uco_transfer: UcoTransfer.changeset(%UcoTransfer{}, %{}),
      changeset_token_transfer: TokenTransfer.changeset(%TokenTransfer{}, %{}),
      validation_timestamp: default_validation_timestamp,
      contract_address: "",
      display_mock_values_input: false,
      input_transaction: nil,
      display_code_block: false
    })
  end
end
