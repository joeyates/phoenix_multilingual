defmodule TestProjectWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  import PhoenixMultilingual.Routes, only: [metadata: 1, metadata: 2]

  scope "/", TestProjectWeb do
    # A Phoenix view
    get("/about", PageController, :about, metadata("en"))
    get("/it/chi-siamo", PageController, :about, metadata("it"))

    # A Phoenix view with a parameter
    get("/contacts/:name", PageController, :contact, metadata("en"))
    get("/it/contatti/:name", PageController, :contact, metadata("it"))

    # A Phoenix view with different `:plug_opts` values
    get("/projects", PageController, :projects_en, metadata(:projects, "en"))
    get("/it/progetti", PageController, :projects_it, metadata(:projects, "it"))

    # A monolingual Phoenix view
    get("/monolingual", PageController, :monolingual)

    # A Phoenix LiveView
    live("/live/about", AboutLive, :index, metadata("en"))
    live("/it/live/chi-siamo", AboutLive, :index, metadata("it"))

    # A route with a parameter for a Phoenix LiveView
    live("/live/contacts/:name", ContactsLive, :index, metadata("en"))
    live("/it/live/contatti/:name", ContactsLive, :index, metadata("it"))
  end
end
