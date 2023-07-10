defmodule ArchethicPlayground.Transaction.TokenTransfer do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  import ArchethicPlayground.Utils.Validation

  @type t :: %__MODULE__{
          amount: float(),
          to: String.t(),
          token_address: String.t(),
          token_id: integer()
        }

  @derive {Jason.Encoder, except: [:id]}
  embedded_schema do
    field(:amount, :float)
    field(:to, :string)
    field(:token_address, :string)
    field(:token_id, :integer)
  end

  @doc false
  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [:amount, :to, :token_address, :token_id])
    |> validate_required([:amount, :to, :token_address])
    |> validate_base_16_address(:to)
    |> validate_base_16_address(:token_address)
  end
end
