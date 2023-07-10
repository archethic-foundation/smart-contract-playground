defmodule ArchethicPlayground.Transaction.Recipient do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  import ArchethicPlayground.Utils.Validation

  @type t :: %__MODULE__{
          address: String.t()
        }

  @derive {Jason.Encoder, except: [:id]}
  embedded_schema do
    field(:address, :string)
  end

  @doc false
  def changeset(recipient, attrs \\ %{}) do
    recipient
    |> cast(attrs, [:address])
    |> validate_required([:address])
    |> validate_base_16_address(:address)
  end
end
