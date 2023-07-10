defmodule ArchethicPlayground.TriggerForm do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__.Mock
  alias ArchethicPlayground.Transaction

  @type t :: %__MODULE__{
          trigger: String.t(),
          transaction: nil | Transaction.t(),
          mocks: list(Mock.t())
        }

  embedded_schema do
    field(:trigger, :string)
    embeds_one(:transaction, Transaction, on_replace: :delete)
    embeds_many(:mocks, Mock, on_replace: :delete)
  end

  @doc false
  def new(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc false
  def changeset(trigger_form, attrs \\ %{}) do
    trigger_form
    |> cast(attrs, [:trigger])
    |> cast_embed(:transaction, with: &Transaction.changeset/2)
    |> cast_embed(:mocks)
    |> validate_required([:trigger])
  end

  def add_empty_mock(changeset) do
    trigger_form = changeset |> apply_changes()
    mocks = trigger_form.mocks ++ [Mock.new()]

    trigger_form
    |> change()
    |> put_embed(:mocks, mocks)
  end

  def remove_mock_at(changeset, index) do
    trigger_form = changeset |> apply_changes()
    mocks = List.delete_at(trigger_form.mocks, index)

    trigger_form
    |> change()
    |> put_embed(:mocks, mocks)
  end

  def create_transaction(changeset, type) do
    transaction =
      case type do
        "oracle" ->
          Transaction.new(%{
            "type" => "oracle",
            "content" => Jason.encode!(%{"uco" => %{"usd" => "0.934", "eur" => "0.911"}})
          })

        "data" ->
          Transaction.new(%{"type" => "data"})

        _ ->
          Transaction.new()
      end

    changeset
    |> put_embed(:transaction, transaction)
  end

  def remove_transaction(changeset) do
    changeset
    |> put_embed(:transaction, nil)
  end
end
