defmodule ArchethicPlaygroundWeb.ConsoleComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-2/4 py-2">
      <h2 class="text-lg font-medium text-gray-400 ml-4">Console</h2>
      <div class="relative mt-2 flex-1 px-2 sm:px-2">
         <!-- Terminal -->
        <div class="absolute inset-0 px-2 sm:px-2">
          <div class="h-full border-2 border border-gray-500 bg-black text-gray-200 p-4 overflow-y-auto">
            <div class="block">
              <%= for {datetime, msg} <- @console_messages do %>
                <p>[ <%= Calendar.strftime(datetime, "%H:%M:%S:%f") %> ]<br /> <%= inspect msg %></p>
              <% end %>
            </div>
          </div>
        </div>
        <!-- /end Terminal -->
      </div>
    </div>
    """
  end
end
