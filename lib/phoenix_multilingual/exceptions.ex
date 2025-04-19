defmodule PhoenixMultilingual.MissingViewDataInConnError do
  defexception []

  def message(_exception) do
    ~S"""
    The connection does not have the expected view data.

    Ensure that you have the PhoenixMultilingual.Plugs.StoreView plug in your router.

    ## Example

        defmodule MyAppWeb.Router do
          use MyAppWeb, :router

          alias PhoenixMultilingual.Plugs.StoreView

          pipeline :browser do
            ...
            plug StoreView, default_locale: "en"
          end
        end
    """
  end
end

defmodule PhoenixMultilingual.MissingViewDataInSocketError do
  defexception []

  def message(_exception) do
    ~S"""
    The socket does not have the expected view data.

    Ensure that you have the PhoenixMultilingual.Hooks.StoreView in your LiveView.

    ## Example

        defmodule MyAppWeb.HomeLive do
          use MyAppWeb, :live_view

          alias PhoenixMultilingual.Plugs.StoreView

          on_mount {StoreView, default_locale: "en"}
        end
    """
  end
end
