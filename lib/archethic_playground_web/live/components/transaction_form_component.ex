defmodule ArchethicPlaygroundWeb.TransactionFormComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component
  alias ArchethicPlayground.Transaction

  def update(assigns, socket) do
    assigns =
      Map.put(
        assigns,
        :form,
        assigns.transaction
        |> Ecto.Changeset.change()
        |> to_form()
      )

    {:ok, assign(socket, assigns)}
  end

  def on("on-form-change", %{"transaction" => transaction}, _) do
    Transaction.changeset(%Transaction{}, transaction)
    |> Ecto.Changeset.apply_changes()
  end

  def on("add-recipient", _, transaction) do
    transaction
    |> Transaction.append_empty_recipient()
  end

  def on("remove-recipient", %{"index" => index}, transaction) do
    index = String.to_integer(index)

    transaction
    |> Transaction.remove_recipient_at(index)
  end

  def on("add-uco-transfer", _, transaction) do
    transaction
    |> Transaction.append_empty_uco_transfer()
  end

  def on("remove-uco-transfer", %{"index" => index}, transaction) do
    index = String.to_integer(index)

    transaction
    |> Transaction.remove_uco_transfer_at(index)
  end

  def on("add-token-transfer", _, transaction) do
    transaction
    |> Transaction.append_empty_token_transfer()
  end

  def on("remove-token-transfer", %{"index" => index}, transaction) do
    index = String.to_integer(index)

    transaction
    |> Transaction.remove_token_transfer_at(index)
  end

  def on("add-ownership", _, transaction) do
    transaction
    |> Transaction.append_empty_ownership()
  end

  def on("remove-ownership", %{"index" => index}, transaction) do
    index = String.to_integer(index)

    transaction
    |> Transaction.remove_ownership_at(index)
  end

  def on("add-ownership-public-key", %{"ownership-index" => ownership_index}, transaction) do
    ownership_index = String.to_integer(ownership_index)

    transaction
    |> Transaction.add_empty_public_key_on_ownership_at(ownership_index)
  end

  def on(
        "remove-ownership-public-key",
        %{"ownership-index" => ownership_index, "public-key-index" => public_key_index},
        transaction
      ) do
    ownership_index = String.to_integer(ownership_index)
    public_key_index = String.to_integer(public_key_index)

    transaction
    |> Transaction.remove_public_key_on_ownership_at(ownership_index, public_key_index)
  end

  defp list_transaction_types() do
    Transaction.types()
  end

  defp number_opts() do
    [step: "0.00000001", min: 0.00000001]
  end
end
