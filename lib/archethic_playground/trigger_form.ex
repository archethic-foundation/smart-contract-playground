defmodule ArchethicPlayground.TriggerForm do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias ArchethicPlayground.Transaction
  alias ArchethicPlayground.RecipientForm

  @type t :: %__MODULE__{
          trigger: String.t(),
          transaction: nil | Transaction.t(),
          recipient: nil | RecipientForm.t()
        }

  @derive {Jason.Encoder, except: [:id]}
  embedded_schema do
    field(:trigger, :string)
    embeds_one(:recipient, RecipientForm, on_replace: :delete)
    embeds_one(:transaction, Transaction, on_replace: :delete)
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
    |> cast_embed(:recipient)
    |> validate_required([:trigger])
  end

  def set_recipient(changeset, recipient) do
    changeset
    |> put_embed(:recipient, recipient)
  end

  def set_transaction(changeset, transaction) do
    changeset
    |> put_embed(:transaction, transaction)
  end

  def remove_transaction(changeset) do
    changeset
    |> put_embed(:transaction, nil)
  end

  def remove_recipient(changeset) do
    changeset
    |> put_embed(:recipient, nil)
  end

  def deserialize_trigger("oracle"), do: :oracle
  def deserialize_trigger("transaction"), do: {:transaction, nil, nil}

  def deserialize_trigger(trigger_str) do
    [key, rest] = String.split(trigger_str, ":")

    case key do
      "interval" ->
        {:interval, rest}

      "datetime" ->
        {:datetime,
         rest
         |> String.to_integer()
         |> DateTime.from_unix!()}

      "transaction" ->
        [action, joined_args] = Regex.run(~r/(\w+)\(([\w, ]*)\)/, rest, capture: :all_but_first)

        args_names =
          case joined_args do
            "" ->
              []

            _ ->
              joined_args |> String.split(",") |> Enum.map(&String.trim/1)
          end

        {:transaction, action, args_names}
    end
  end

  def serialize_trigger({:interval, interval}), do: "interval:#{interval}"
  def serialize_trigger({:datetime, datetime}), do: "datetime:#{DateTime.to_unix(datetime)}"
  def serialize_trigger(:oracle), do: "oracle"
  def serialize_trigger({:transaction, nil, nil}), do: "transaction"

  def serialize_trigger({:transaction, action, args_names}),
    do: "transaction:#{action}(#{Enum.join(args_names, ",")})"
end
