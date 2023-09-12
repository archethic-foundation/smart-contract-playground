defmodule ArchethicPlayground.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__.Recipient
  alias __MODULE__.UcoTransfer
  alias __MODULE__.TokenTransfer
  alias __MODULE__.Ownership

  alias Archethic.Crypto
  alias Archethic.TransactionChain.Transaction, as: ArchethicTransaction
  alias Archethic.TransactionChain.TransactionData
  alias Archethic.TransactionChain.TransactionData.Recipient, as: ArchethicRecipient
  alias ArchethicPlayground.Utils

  @type t :: %__MODULE__{
          type: String.t(),
          content: String.t(),
          code: String.t(),
          validation_timestamp: String.t(),
          address: String.t(),
          recipients: list(Recipient.t()),
          uco_transfers: list(UcoTransfer.t()),
          token_transfers: list(TokenTransfer.t()),
          ownerships: list(Ownership.t())
        }

  @derive {Jason.Encoder, except: [:__meta__, :id]}
  schema "transaction" do
    field(:type, :string)
    field(:content, :string, default: "")
    field(:code, :string, default: "")
    field(:validation_timestamp, :string)
    field(:address, :string)
    embeds_many(:recipients, Recipient, on_replace: :delete)
    embeds_many(:uco_transfers, UcoTransfer, on_replace: :delete)
    embeds_many(:token_transfers, TokenTransfer, on_replace: :delete)
    embeds_many(:ownerships, Ownership, on_replace: :delete)
  end

  def types() do
    types =
      Archethic.TransactionChain.Transaction.types()
      |> Enum.reject(&Archethic.TransactionChain.Transaction.network_type?/1)

    # we want to be able to trigger oracle transaction (event if its network)
    [:oracle | types]
    |> Enum.sort()
  end

  def changeset(transaction, attrs \\ %{}) do
    transaction
    |> cast(attrs, [:type, :content, :code, :address, :validation_timestamp])
    |> cast_embed(:uco_transfers)
    |> cast_embed(:token_transfers)
    |> cast_embed(:recipients)
    |> cast_embed(:ownerships)
    |> validate_required([:type])
  end

  def new(attrs \\ %{}) do
    if Map.has_key?(attrs, :validation_timestamp) do
      changeset(%__MODULE__{}, attrs)
    else
      attrs =
        Map.put_new(
          attrs,
          "validation_timestamp",
          Utils.Date.datetime_to_browser_timestamp(DateTime.utc_now())
        )

      changeset(%__MODULE__{}, attrs)
    end
  end

  def append_empty_recipient(transaction) do
    %__MODULE__{
      transaction
      | recipients: transaction.recipients ++ [%Recipient{}]
    }
  end

  def remove_recipient_at(transaction, index) do
    %__MODULE__{transaction | recipients: List.delete_at(transaction.recipients, index)}
  end

  def append_empty_uco_transfer(transaction) do
    %__MODULE__{transaction | uco_transfers: transaction.uco_transfers ++ [%UcoTransfer{}]}
  end

  def remove_uco_transfer_at(transaction, index) do
    %__MODULE__{transaction | uco_transfers: List.delete_at(transaction.uco_transfers, index)}
  end

  def append_empty_token_transfer(transaction) do
    %__MODULE__{
      transaction
      | token_transfers: transaction.token_transfers ++ [%TokenTransfer{}]
    }
  end

  def remove_token_transfer_at(transaction, index) do
    %__MODULE__{
      transaction
      | token_transfers: List.delete_at(transaction.token_transfers, index)
    }
  end

  def append_empty_ownership(transaction) do
    %__MODULE__{transaction | ownerships: transaction.ownerships ++ [%Ownership{}]}
  end

  def remove_ownership_at(transaction, index) do
    %__MODULE__{transaction | ownerships: List.delete_at(transaction.ownerships, index)}
  end

  def add_empty_public_key_on_ownership_at(transaction, index) do
    %__MODULE__{
      transaction
      | ownerships: List.update_at(transaction.ownerships, index, &Ownership.append_empty_key/1)
    }
  end

  def remove_public_key_on_ownership_at(transaction, ownership_index, public_key_index) do
    %__MODULE__{
      transaction
      | ownerships:
          List.update_at(transaction.ownerships, ownership_index, fn ownership ->
            Ownership.remove_key_at(ownership, public_key_index)
          end)
    }
  end

  def add_contract_ownership(transaction, seed, storage_nonce_pubkey) do
    contract_ownership = %Ownership{
      secret: seed,
      authorized_keys: [storage_nonce_pubkey]
    }

    %__MODULE__{transaction | ownerships: [contract_ownership | transaction.ownerships]}
  end

  # used to print in console
  def to_short_map(t = %__MODULE__{}, opts) do
    filter_code? = Keyword.get(opts, :filter_code, false)

    Map.from_struct(t)
    |> Enum.reject(fn {key, value} ->
      key == :__meta__ || value == nil || value == [] || value == "" ||
        (filter_code? && key == :code)
    end)
    |> Enum.into(%{})
  end

  @spec to_archethic(t()) :: ArchethicTransaction.t()
  def to_archethic(t = %__MODULE__{}) do
    tx = %ArchethicTransaction{
      type: String.to_existing_atom(t.type),
      address: hex_to_bin(t.address),
      data: %TransactionData{
        code: t.code,
        content: t.content,
        ledger: %TransactionData.Ledger{
          token: %TransactionData.TokenLedger{
            transfers:
              Enum.map(t.token_transfers, fn t ->
                %TransactionData.TokenLedger.Transfer{
                  token_address: hex_to_bin(t.token_address),
                  to: hex_to_bin(t.to),
                  amount: Archethic.Utils.to_bigint(t.amount),
                  token_id: t.token_id
                }
              end)
          },
          uco: %TransactionData.UCOLedger{
            transfers:
              Enum.map(t.uco_transfers, fn t ->
                %TransactionData.UCOLedger.Transfer{
                  to: hex_to_bin(t.to),
                  amount: Archethic.Utils.to_bigint(t.amount)
                }
              end)
          }
        },
        recipients:
          Enum.map(t.recipients, fn
            %Recipient{address: address, action: "", args_json: ""} ->
              %ArchethicRecipient{
                address: hex_to_bin(address)
              }

            %Recipient{address: address, action: action, args_json: args_json} ->
              %ArchethicRecipient{
                address: hex_to_bin(address),
                action: action,
                args:
                  case Jason.decode(args_json) do
                    {:ok, args} when is_list(args) -> args
                    _ -> []
                  end
              }
          end),
        ownerships:
          Enum.map(t.ownerships, fn o ->
            aes_key = :crypto.strong_rand_bytes(32)

            %TransactionData.Ownership{
              secret: Crypto.aes_encrypt(o.secret, aes_key),
              authorized_keys:
                o.authorized_keys
                |> Enum.map(&hex_to_bin/1)
                |> Enum.map(&{&1, Crypto.ec_encrypt(aes_key, &1)})
                |> Enum.into(%{})
            }
          end)
      }
    }

    %ArchethicTransaction{
      tx
      | validation_stamp: %ArchethicTransaction.ValidationStamp{
          ArchethicTransaction.ValidationStamp.generate_dummy()
          | timestamp: Utils.Date.browser_timestamp_to_datetime(t.validation_timestamp),
            ledger_operations: %ArchethicTransaction.ValidationStamp.LedgerOperations{
              transaction_movements: ArchethicTransaction.get_movements(tx)
            }
        }
    }
  end

  def from_archethic(nil), do: nil

  def from_archethic(t = %ArchethicTransaction{}) do
    # TODO: ownerships... not sure what to do
    %__MODULE__{
      type: Atom.to_string(t.type),
      address: bin_to_hex(t.address),
      code: t.data.code,
      content: t.data.content,
      validation_timestamp:
        if t.validation_stamp != nil do
          Utils.Date.datetime_to_browser_timestamp(t.validation_stamp.timestamp)
        else
          # happens because the output transaction is not actually validated
          Utils.Date.datetime_to_browser_timestamp(DateTime.utc_now())
        end,
      uco_transfers:
        Enum.map(t.data.ledger.uco.transfers, fn t ->
          %UcoTransfer{
            to: bin_to_hex(t.to),
            amount: Archethic.Utils.from_bigint(t.amount)
          }
        end),
      token_transfers:
        Enum.map(t.data.ledger.token.transfers, fn t ->
          %TokenTransfer{
            token_address: bin_to_hex(t.token_address),
            token_id: t.token_id,
            to: bin_to_hex(t.to),
            amount: Archethic.Utils.from_bigint(t.amount)
          }
        end),
      recipients:
        Enum.map(t.data.recipients, fn
          %ArchethicRecipient{address: address, action: nil, args: nil} ->
            %Recipient{
              address: bin_to_hex(address)
            }

          %ArchethicRecipient{address: address, action: action, args: args} ->
            %Recipient{
              address: bin_to_hex(address),
              action: action,
              args_json: Jason.encode!(args)
            }
        end)
    }
  end

  defp hex_to_bin(nil), do: nil

  defp hex_to_bin(hex) do
    case Base.decode16(hex, case: :mixed) do
      {:ok, bin} ->
        bin

      :error ->
        # to be improve later with proper form errors that blocks the trigger/deploy actions
        send(self(), {:console, :warning, "Invalid hexadecimal: #{hex}. Value has been ignored."})
        <<>>
    end
  end

  defp bin_to_hex(nil), do: nil
  defp bin_to_hex(bin), do: Base.encode16(bin)
end
