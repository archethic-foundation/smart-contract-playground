defmodule ArchethicPlaygroundWeb.Router do
  @moduledoc false

  use ArchethicPlaygroundWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {ArchethicPlaygroundWeb.LayoutView, :root})
  end

  scope "/", ArchethicPlaygroundWeb do
    pipe_through(:browser)
    # live("/editor", EditorLive)
    get("/", RootController, :index)
  end
end
