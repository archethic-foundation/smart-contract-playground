defmodule ArchethicPlaygroundWeb.TriggerComponent do
  @moduledoc false

  use ArchethicPlaygroundWeb, :live_component

  alias ArchethicPlayground.TriggerForm
  alias ArchethicPlayground.Utils
  alias ArchethicPlaygroundWeb.TransactionFormComponent

  def mount(socket) do
    socket =
      socket
      |> assign(:mock_functions, [
        "Chain.get_genesis_address/1",
        "Chain.get_first_transaction_address/1",
        "Chain.get_genesis_public_key/1",
        "Time.now/0",
        "Token.fetch_id_from_address/1"
      ])

    {:ok, assign_form(socket, reset_form())}
  end

  def handle_event("on-form-change", params = %{"trigger_form" => trigger_form}, socket) do
    previous_trigger_form = socket.assigns.form.source |> Ecto.Changeset.apply_changes()

    # when the trigger change we reset the form
    form =
      if params["_target"] == ["trigger_form", "trigger"] do
        case trigger_form["trigger"] do
          "transaction" ->
            TriggerForm.changeset(previous_trigger_form, trigger_form)
            |> TriggerForm.create_transaction("data")

          "oracle" ->
            TriggerForm.changeset(previous_trigger_form, trigger_form)
            |> TriggerForm.create_transaction("oracle")

          _ ->
            TriggerForm.changeset(previous_trigger_form, trigger_form)
            |> TriggerForm.remove_transaction()
        end
      else
        TriggerForm.changeset(previous_trigger_form, trigger_form)
      end

    {:noreply, assign_form(socket, form)}
  end

  def handle_event("transaction_form:" <> event_name, params, socket) do
    trigger_form =
      socket.assigns.form.source
      |> Ecto.Changeset.apply_changes()

    transaction =
      TransactionFormComponent.on(event_name, params, trigger_form.transaction)
      |> Utils.Struct.deep_struct_to_map()

    form =
      socket.assigns.form.source
      |> TriggerForm.changeset(%{"transaction" => transaction})

    {:noreply, assign_form(socket, form)}
  end

  def handle_event("add-mock", _, socket) do
    form =
      socket.assigns.form.source
      |> TriggerForm.add_empty_mock()

    {:noreply, assign_form(socket, form)}
  end

  def handle_event("remove-mock", %{"index" => index}, socket) do
    index = String.to_integer(index)

    form =
      socket.assigns.form.source
      |> TriggerForm.remove_mock_at(index)

    {:noreply, assign_form(socket, form)}
  end

  def handle_event("trigger-stateful", _, socket) do
    send(
      self(),
      {:execute_contract, Ecto.Changeset.apply_changes(socket.assigns.form.source), true}
    )

    {:noreply, socket}
  end

  def handle_event("trigger-stateless", _, socket) do
    send(
      self(),
      {:execute_contract, Ecto.Changeset.apply_changes(socket.assigns.form.source), false}
    )

    {:noreply, socket}
  end

  defp assign_form(socket, form) do
    assign(socket, form: to_form(form))
  end

  defp reset_form() do
    %TriggerForm{}
    |> Ecto.Changeset.change()
  end
end
