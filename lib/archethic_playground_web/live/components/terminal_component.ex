defmodule ArchethicPlaygroundWeb.TerminalComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div
    x-data="{ open: true }"
    @keydown.window.escape="open = false"
    @open-terminal.window="if ($event.detail.id == 1) open = true"
    x-show="open"
    class="relative z-10"
    x-ref="dialog"
    >
    <div class="fixed inset-0 overflow-hidden">
     <div class="absolute inset-0 overflow-hidden">
       <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
             <div
              x-show="open"
              x-transition:enter="transform transition ease-in-out duration-500 sm:duration-700"
              x-transition:enter-start="translate-x-full"
              x-transition:enter-end="translate-x-0"
              x-transition:leave="transform transition ease-in-out duration-500 sm:duration-700"
              x-transition:leave-start="translate-x-0"
              x-transition:leave-end="translate-x-full"
              class="pointer-events-auto relative w-screen max-w-2xl"
              @click.away="open = false">

                  <div x-show="open"
                  x-transition:enter="ease-in-out duration-500"
                  x-transition:enter-start="opacity-0"
                  x-transition:enter-end="opacity-100"
                  x-transition:leave="ease-in-out duration-500"
                  x-transition:leave-start="opacity-100"
                  x-transition:leave-end="opacity-0"
                  class="absolute top-0 left-0 -ml-8 flex pt-20 pr-2">

                    <button type="button" class="rounded-md text-gray-300 hover:text-white focus:outline-none focus:ring-2 focus:ring-white" @click="open = false">
                        <span class="sr-only">Close panel</span>
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="w-6 h-6" viewBox="0 0 16 16">
                          <path d="M6 9a.5.5 0 0 1 .5-.5h3a.5.5 0 0 1 0 1h-3A.5.5 0 0 1 6 9zM3.854 4.146a.5.5 0 1 0-.708.708L4.793 6.5 3.146 8.146a.5.5 0 1 0 .708.708l2-2a.5.5 0 0 0 0-.708l-2-2z"/>
                          <path d="M2 1a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V3a2 2 0 0 0-2-2H2zm12 1a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1h12z"/>
                        </svg>
                    </button>
           </div>

            <div class="flex h-full flex-col overflow-y-scroll bg-gray-800 py-6 shadow-xl">
             <div class="px-4 sm:px-6">
               <h2 class="text-lg font-medium text-gray-400" id="slide-over-title">Terminal</h2>
             </div>
             <div class="relative mt-6 flex-1 px-2 sm:px-2">
               <!-- Terminal -->
               <div class="absolute inset-0 px-2 sm:px-2">
                 <div class="h-full border-2 border border-gray-500 bg-black text-gray-200 p-4" aria-hidden="true">
                  <%= for terminal <- @terminal do %>
                    <%= terminal.time %> : <%= terminal.status |> Atom.to_string() |> String.upcase() %>
                    <%= terminal.message %>
                  <% end %>
                 </div>
               </div>
               <!-- /end Terminal -->
             </div>
           </div>
         </div>
       </div>
     </div>
    </div>
    </div>
    """
  end
end
