if Code.ensure_loaded?(Phoenix.Component) do
  defmodule PhoenixMultilingual.HTML do
    import PhoenixMultilingual.Components
    alias PhoenixMultilingual.Routes
    alias PhoenixMultilingual.View

    @doc """
    Builds a list of data for rel links for the document head.

    ## Example

    In the router:

        scope "/", MyAppWeb do
          get "/about", PageController, :index, metadata("en")
          get "/it/chi-siamo", PageController, :index, metadata("it")
        end

    In the `<head>` of the layout template:

        <%= get_rel_links(@conn) %>

    Result:

        <link rel="canonical" href="https://example.com/about">
        <link rel="alternate" hreflang="it" href="https://example.com/it/chi-siamo">
    """
    def get_rel_links(%Plug.Conn{} = conn) do
      path = View.fetch_key(conn, :path)
      locale = View.fetch_key(conn, :locale)

      case Routes.build_page_mapping(conn, path) do
        {:ok, mapping} ->
          rels = build_rels(conn, locale, mapping)
          rel_links(%{rels: rels})

        _ ->
          ""
      end
    end

    defp build_rels(conn, page_locale, mapping) do
      mapping
      |> Enum.map(fn {locale, path} ->
        url = Phoenix.VerifiedRoutes.unverified_url(conn, path)

        if locale == page_locale do
          {"canonical", nil, url}
        else
          {"alternate", locale, url}
        end
      end)
    end
  end
end
