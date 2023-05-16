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
      |> assign(:console_messages, [])
      |> assign(:is_show_trigger, false)
      |> assign(:is_show_deploy, false)
      |> assign(:smart_contract_code, "")

    {:ok, socket}
  end

  def handle_event("interpret", %{"code" => code}, socket) do
    send(self(), {:console, :clear})

    {socket, result} =
      case ArchethicPlayground.interpret(code) do
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
              smart_contract_code: code
            ),
            %{status: :ok, message: "Contract is successfully validated"}
          }

        {:error, message} ->
          send(self(), {:console, message})
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

  def handle_info({:console, :clear}, socket) do
    {:noreply, assign(socket, console_messages: [])}
  end

  def handle_info({:console, data}, socket) do
    dated_data = {DateTime.utc_now(), data}
    {:noreply, assign(socket, console_messages: socket.assigns.console_messages ++ [dated_data])}
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
