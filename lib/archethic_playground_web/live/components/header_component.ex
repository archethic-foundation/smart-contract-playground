defmodule ArchethicPlaygroundWeb.HeaderComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <header class="flex-none z-10 py-4 bg-white shadow-md dark:bg-gray-800">
    <div
            class="flex items-center justify-between h-full px-6 mx-auto text-purple-600 dark:text-purple-300"
          >
    <!-- Brand/Logo -->
    <a class="ml-1 text-lg font-bold text-gray-800 dark:text-gray-200"
            href="#"
          >
      Archethic Playground
    </a>
    <!-- end Brand -->
    <!-- Mobile hamburger -->
    <button
              class="p-1 mr-5 -ml-1 rounded-md md:hidden focus:outline-none focus:shadow-outline-purple"
              @click="toggleSideMenu"
              aria-label="Menu"
            >
      <svg
                class="w-6 h-6"
                aria-hidden="true"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
        <path
                  fill-rule="evenodd"
                  d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z"
                  clip-rule="evenodd"
                ></path>
      </svg>
    </button>
    <ul class="flex items-center flex-shrink-0 space-x-6">
      <!-- menu.website -->
      <li class="relative">
        <a class="ml-1 font-sm text-gray-800 dark:text-gray-200"
            href="https://archethic.net/"
            target="_blank"
            data-tippy-content="Archethic Website"
          >
          Archethic Website
        </a>
      </li>
      <!-- end menu.website -->
      <!-- menu.GitHub -->
      <li class="inline-flex">
        <a
           class="inline-flex items-center w-full text-sm font-semibold transition-colors duration-150 hover:text-gray-800 dark:hover:text-gray-200"
            href="https://github.com/archethic-foundation"
            target="_blank"
            data-tippy-content="GitHub Repos"
          >
          <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 18 18" class="w-8 h-8">
            <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42-3.58-8-8-8z"/>
          </svg>
        </a>
      </li>
      <!-- end menu.GitHub -->
    </ul>
    </div>
    </header>
    """
  end
end
