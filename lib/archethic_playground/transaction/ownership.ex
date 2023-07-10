defmodule ArchethicPlayground.Transaction.Ownership do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          secret: String.t(),
          authorized_keys: list(String.t())
        }

  @derive {Jason.Encoder, except: [:id]}
  embedded_schema do
    field(:secret, :string)
    field(:authorized_keys, {:array, :string}, default: [])
  end

  @doc false
  def changeset(ownership, params = %{}) do
    ownership
    |> cast(params, [:secret, :authorized_keys])
    |> validate_required([:secret, :authorized_keys])
    |> validate_length(:authorized_keys,
      max: 256,
      min: 1,
      message: "maximum number of authorized keys can be 256"
    )
  end

  def append_empty_key(ownership) do
    %__MODULE__{ownership | authorized_keys: ownership.authorized_keys ++ [""]}
  end

  def remove_key_at(ownership, index) do
    %__MODULE__{ownership | authorized_keys: List.delete_at(ownership.authorized_keys, index)}
  end
end
