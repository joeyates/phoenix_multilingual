if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule PhoenixMultilingual.Hooks.StoreView do
    @moduledoc """
    Store the view information in the LiveView socket's private data.

    This hook **must** be registered for each LiveView in order
    to enable all other Phoenix Multilingual features in Phoenix live views.

    ## Example

        defmodule MyAppWeb.HomeLive do
          use MyAppWeb, :live_view

          alias PhoenixMultilingual.Hooks.StoreView

          on_mount {StoreView, default_locale: "en"}
        end
    """

    import Phoenix.LiveView
    alias PhoenixMultilingual.Routes
    alias PhoenixMultilingual.View

    def on_mount([default_locale: default_locale], _params, _session, socket) do
      socket =
        socket
        |> attach_hook(:multilingual_store_view, :handle_params, fn _params, uri, socket ->
          uri = URI.parse(uri)
          info = Phoenix.Router.route_info(socket.router, "GET", uri.path, nil)
          locale = Routes.path_locale(socket.router, info.route) || default_locale
          view = %View{path: uri.path, locale: locale}
          socket = put_private(socket, :multilingual, view)
          {:cont, socket}
        end)

      {:cont, socket}
    end
  end
end
