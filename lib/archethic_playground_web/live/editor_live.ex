defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false
  alias ArchethicPlaygroundWeb.ConsoleComponent
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent
  alias ArchethicPlaygroundWeb.TriggerComponent

  use Phoenix.LiveView

  # Check live_component dialyzer error for function call mismatch
  # Ignoring it temporarily
  @dialyzer {:nowarn_function, render: 1}

  def mount(_params, _opts, socket) do
    socket =
      socket
      |> assign(:terminal, [])
      |> assign(:triggers, [])
      |> assign(:interpreted_contract, %{})
      |> assign(:trigger_transaction, %{})
      |> assign(:is_show_trigger, false)

    {:ok, socket}
  end

  def handle_event("interpret", %{"contract" => contract}, socket) do
    {socket, result} =
      case ArchethicPlayground.interpret(contract) do
        {:ok, interpreted_contract} ->
          triggers =
            interpreted_contract.triggers
            |> Enum.map(fn {key, _} ->
              key
              |> case do
                {:interval, interval} ->
                  "interval:#{interval}"

                {:datetime, datetime} ->
                  "datetime:#{DateTime.to_unix(datetime)}"

                :oracle ->
                  "oracle"

                :transaction ->
                  "transaction"
              end
            end)

          {
            assign(socket, triggers: triggers, interpreted_contract: interpreted_contract),
            %{status: :ok, message: "Contract is successfully validated"}
          }

        {:error, message} ->
          {socket, %{status: :error, message: message}}
      end

    {:reply, %{result: result}, socket}
  end

  def handle_event("toggle_trigger", _, socket) do
    {:noreply, assign(socket, is_show_trigger: not socket.assigns.is_show_trigger)}
  end

  def handle_info({:trigger_transaction, trigger_transaction}, socket) do
    {:noreply, assign(socket, trigger_transaction: trigger_transaction)}
  end

  # def handle_event("interpret", %{"code" => code}, socket) do
  #   # ArchethicPlayground.interpret(code)

  #   {:reply, %{status: "ok"}, socket}
  # end
end
