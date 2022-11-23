defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false
  alias ArchethicPlaygroundWeb.HeaderComponent
  alias ArchethicPlaygroundWeb.SidebarComponent

  use Phoenix.LiveView

  # Check live_component dialyzer error for function call mismatch
  # Ignoring it temporarily
  @dialyzer {:nowarn_function, render: 1}

  def render(assigns) do
    ~H"""
    <div class="flex bg-gray-50 dark:bg-gray-900" >
    <.live_component module={SidebarComponent} id="sidebar" />
      <div class="flex h-screen flex-col flex-1">
      <.live_component module={HeaderComponent} id="header" />
          <!-- monaco.editor -->
          <div class="h-screen" id="archethic-editor" phx-hook="hook_LoadEditor" phx-update="ignore" data-debounce-validation="1000">
          </div>
          <!-- end monaco.editor -->
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

    {:reply, %{result: result}, socket}
  end

  # def handle_event("interpret", %{"code" => code}, socket) do
  #   # ArchethicPlayground.interpret(code)

  #   {:reply, %{status: "ok"}, socket}
  # end
end
