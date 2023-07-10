defmodule ArchethicPlayground.TriggerForm.Mock do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  # for now only deal with arity 1 and 0
  @type t :: %__MODULE__{
          function: String.t(),
          input: String.t() | nil,
          output: String.t()
        }

  embedded_schema do
    field(:function, :string)
    field(:input, :string)
    field(:output, :string)
  end

  @doc false
  def new(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc false
  def changeset(mock, attrs \\ %{}) do
    mock
    |> cast(attrs, [:function, :input, :output])
    |> validate_required([:function, :output])
  end
end
