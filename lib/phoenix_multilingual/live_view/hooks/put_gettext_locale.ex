if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule PhoenixMultilingual.Hooks.PutGettextLocale do
    @moduledoc """
    Sets the Gettext locale in the LiveView socket
    based on the locale stored in the socket's private data.

    This hook must follow the StoreView hook in the LiveView's
    `on_mount` hook list.

    ## Example

        defmodule MyAppWeb.HomeLive do
          use MyAppWeb, :live_view

          alias PhoenixMultilingual.Hooks.StoreView
          alias PhoenixMultilingual.Hooks.PutGettextLocale

          on_mount {StoreView, default_locale: "en"}
          on_mount PutGettextLocale
        end
    """

    import Phoenix.LiveView
    alias PhoenixMultilingual.View

    def on_mount(:default, _params, _session, socket) do
      socket =
        socket
        |> attach_hook(:multilingual_put_locale, :handle_params, fn _params, _uri, socket ->
          locale = View.fetch_key(socket, :locale)
          Gettext.put_locale(locale)
          {:cont, socket}
        end)

      {:cont, socket}
    end
  end
end
