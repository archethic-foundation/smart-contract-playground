defmodule ArchethicPlaygroundWeb.ContractComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias ArchethicPlaygroundWeb.TransactionFormComponent

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("clear-form", _, socket) do
    send(self(), :reset_transaction_contract)
    {:noreply, socket}
  end

  def handle_event("transaction_form:" <> event_name, params, socket) do
    transaction = TransactionFormComponent.on(event_name, params, socket.assigns.transaction)
    send(self(), {:set_transaction_contract, transaction})
    {:noreply, socket}
  end
end
