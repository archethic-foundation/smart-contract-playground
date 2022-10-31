defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent
  alias ArchethicPlaygroundWeb.TerminalComponent

  use Phoenix.LiveView

  # Check live_component dialyzer error for function call mismatch
  # Ignoring it temporarily
  @dialyzer {:nowarn_function, render: 1}

  def render(assigns) do
    ~L"""
    <div class="flex bg-gray-50 dark:bg-gray-900" >
    <%= live_component @socket, SidebarComponent, assigns %>
      <div class="flex h-screen flex-col flex-1">
        <%= live_component @socket, HeaderComponent, assigns %>
          <!-- monaco.editor -->
          <div class="h-screen" id="archethic-editor" phx-hook="hook_LoadEditor" phx-update="ignore">
          </div>
          <!-- end monaco.editor -->
       <%= live_component @socket, TerminalComponent, assigns %>
      </div>
    </div>
    """
  end

  def mount(_params, _opts, socket) do
    socket =
      socket
      |> assign(:terminal, [])

    {:ok, socket}
  end

  def handle_event("interpret", %{"contract" => contract}, socket) do
    result =
      case ArchethicPlayground.interpret(contract) do
        {:ok, _interpreted_contract} ->
          %{status: :ok, message: "Contract is successfully validated"}

        {:error, message} ->
          %{status: :error, message: message}
      end

    # Time of execution. Picking NaiveDateTime to show the local
    # execution time
    result =
      result
      |> Map.put(:time, NaiveDateTime.local_now())

    terminal = [result | socket.assigns.terminal]

    socket =
      socket
      |> assign(:terminal, terminal)

    {:reply, %{}, socket}
  end

  # def handle_event("interpret", %{"code" => code}, socket) do
  #   # ArchethicPlayground.interpret(code)

  #   {:reply, %{status: "ok"}, socket}
  # end
end
