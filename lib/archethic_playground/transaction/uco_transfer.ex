defmodule ArchethicPlayground.Transaction.UcoTransfer do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  import ArchethicPlayground.Utils.Validation

  @type t :: %__MODULE__{
          amount: float(),
          to: String.t()
        }

  @derive {Jason.Encoder, except: [:id]}
  embedded_schema do
    field(:amount, :float)
    field(:to, :string)
  end

  @doc false
  def changeset(transfer, attrs) do
    transfer
    |> cast(attrs, [:amount, :to])
    |> validate_required([:amount, :to])
    |> validate_base_16_address(:to)
  end
end
