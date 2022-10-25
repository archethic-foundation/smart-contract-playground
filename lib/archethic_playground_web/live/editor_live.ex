defmodule ArchethicPlaygroundWeb.EditorLive do
  @moduledoc false

  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="h-screen w-full" id="archethic-editor">
    </div>
    """
  end

  def mount(_params, _opts, socket) do
    {:ok, socket}
  end

  def handle_event("interpret", %{"code" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("interpret", %{"code" => code}, socket) do
    ArchethicPlayground.interpret(code)
    {:reply, %{status: "ok"}, socket}
  end
end
