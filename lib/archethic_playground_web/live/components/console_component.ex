defmodule ArchethicPlaygroundWeb.ConsoleComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div class="flex flex-col h-2/4 py-2">
      <h2 class="text-lg font-medium text-gray-400 ml-4">Console</h2>
      <div class="relative mt-2 flex-1 px-2 sm:px-2">
         <!-- Terminal -->
        <div class="absolute inset-0 px-2 sm:px-2">
          <div class="h-full border-2 border border-gray-500 bg-black text-gray-200 p-4 overflow-y-auto">
            <%= for terminal <- @terminal do %>
            <div class="block">
              <%= terminal.time %> : <%= terminal.status |> Atom.to_string() |> String.upcase() %>
              <%= terminal.message %>
            </div>
            <% end %>
          </div>
        </div>
        <!-- /end Terminal -->
      </div>
    </div>
    """
  end
end
