defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false
  alias ArchethicPlaygroundWeb.ConsoleComponent
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent
  alias ArchethicPlaygroundWeb.TriggerComponent
  alias ArchethicPlaygroundWeb.DeployComponent

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
      |> assign(:is_show_deploy, false)
      |> assign(:smart_contract_code, "")

    {:ok, socket}
  end

  def handle_event("interpret", %{"contract" => contract}, socket) do
    {socket, result} =
      case ArchethicPlayground.interpret(contract) do
        {:ok, interpreted_contract} ->
          triggers =
            interpreted_contract.triggers
            |> Enum.map(fn {key, _} ->
              get_key(key)
            end)

          {
            assign(socket,
              triggers: triggers,
              interpreted_contract: interpreted_contract,
              smart_contract_code: contract
            ),
            %{status: :ok, message: "Contract is successfully validated"}
          }

        {:error, message} ->
          {socket, %{status: :error, message: message}}
      end

    {:reply, %{result: result}, socket}
  end

  def handle_event("toggle_trigger", _, socket) do
    {:noreply,
     assign(socket,
       is_show_trigger: not socket.assigns.is_show_trigger,
       is_show_deploy: false
     )}
  end

  def handle_event("toggle_deploy", _, socket) do
    {:noreply,
     assign(socket,
       is_show_deploy: not socket.assigns.is_show_deploy,
       is_show_trigger: false
     )}
  end

  def handle_info({:trigger_transaction, trigger_transaction}, socket) do
    {:noreply, assign(socket, trigger_transaction: trigger_transaction)}
  end

  defp get_key({:interval, interval}), do: "interval:#{interval}"
  defp get_key({:datetime, datetime}), do: "datetime:#{DateTime.to_unix(datetime)}"
  defp get_key(:oracle), do: "oracle"
  defp get_key(:transaction), do: "transaction"

  # def handle_event("interpret", %{"code" => code}, socket) do
  #   # ArchethicPlayground.interpret(code)

  #   {:reply, %{status: "ok"}, socket}
  # end
end
