if Code.ensure_loaded?(Gettext) do
  defmodule PhoenixMultilingual.Plugs.PutGettextLocale do
    alias PhoenixMultilingual.View

    def init(_opts), do: nil

    def call(conn, _opts) do
      locale = View.fetch_key(conn, :locale)
      Gettext.put_locale(locale)
      conn
    end
  end
end
