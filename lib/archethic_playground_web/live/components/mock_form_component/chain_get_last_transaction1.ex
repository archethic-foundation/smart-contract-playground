defmodule ArchethicPlaygroundWeb.MockFormComponent.ChainGetLastTransaction1 do
  @moduledoc false

  alias ArchethicPlayground.Transaction
  alias ArchethicPlayground.Mock
  alias ArchethicPlaygroundWeb.TransactionFormComponent
  alias Archethic.Contracts.Constants

  use ArchethicPlaygroundWeb, :live_component

  def name(), do: "Chain.get_last_transaction/1"

  def mount(socket) do
    socket =
      socket
      |> assign(
        form: to_form(%{"address" => nil}),
        transaction: Transaction.new(%{"type" => "data"})
      )

    {:ok, socket}
  end

  # this is triggered only when address changed
  def handle_event("on-form-change", params, socket) do
    mock = %Mock{
      function: name(),
      inputs: [
        params["address"]
        |> String.trim()
        |> String.upcase()
      ],
      output:
        socket.assigns.transaction
        |> transaction_to_constants()
    }

    # update parent
    socket.assigns.on_update.(mock)

    {:noreply, assign(socket, form: to_form(params))}
  end

  # this is triggered when the transaction form changed
  def handle_event("transaction_form:" <> event_name, params, socket) do
    transaction = TransactionFormComponent.on(event_name, params, socket.assigns.transaction)

    mock = %Mock{
      function: name(),
      inputs: [
        socket.assigns.form.source["address"]
        |> String.trim()
        |> String.upcase()
      ],
      output:
        transaction
        |> transaction_to_constants()
    }

    # update parent
    socket.assigns.on_update.(mock)

    {:noreply, assign(socket, transaction: transaction)}
  end

  defp transaction_to_constants(tx) do
    try do
      tx
      |> Transaction.to_archethic()
      |> Constants.from_transaction()
    rescue
      _ ->
        %{}
    end
  end
end
