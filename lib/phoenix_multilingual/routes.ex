defmodule PhoenixMultilingual.Routes do
  alias PhoenixMultilingual.Metadata
  alias PhoenixMultilingual.Routes.{Route, RouteInfo}

  @doc """
  Builds a mapping of locales to paths for the current page.

  ## Examples

  In the router:

      scope "/", MyAppWeb do
        get "/about", PageController, :index, metadata("en")
        get "/it/chi-siamo", PageController, :index, metadata("it")
      end

      > PhoenixMultilingual.Routes.build_page_mapping(Router, "/about")
      {:ok, %{"en" => "/about", "it" => "/it/chi-siamo"}}

  The result can be used to create a language switcher in the view.

      <% locales = ["en", "it"] %>
      <% locale = PhoenixMultilingual.View.fetch_key(@conn, :locale) %>
      <% path = PhoenixMultilingual.View.fetch_key(@conn, :route) %>
      <% {:ok, mapping} = PhoenixMultilingual.Routes.build_page_mapping(@conn, path) %>
      <nav>
        <ul>
          <%= for lcl <- locales do %>
            <%= if lcl == locale do %>
              <li><%= lcl %></li>
            <% else %>
              <%= if mapping[lcl] do %>
                <li><a href={mapping[lcl]}><%= lcl %></a></li>
              <% end %>
            <% end %>
          <% end %>
        </ul>
      </nav>
  """
  def build_page_mapping(%Plug.Conn{} = conn, path) do
    conn
    |> Phoenix.Controller.router_module()
    |> build_page_mapping(path)
  end

  def build_page_mapping(router, path) do
    with {:ok, info} <- route_info(router, path),
         {:ok, route} <- find_route(router, info),
         :ok <- is_localized?(route) do
      router
      |> build_route_mapping(route, info.path_params)
      |> then(&{:ok, &1})
    else
      error ->
        error
    end
  end

  defp is_localized?(route) do
    case route.metadata do
      %{multilingual: _multilingual} -> :ok
      _any -> {:error, :not_localized}
    end
  end

  defp build_route_mapping(router, route, params) do
    router
    |> Phoenix.Router.routes()
    |> Enum.reduce(
      %{},
      fn other, mapping ->
        with true <- same_view?(route, other),
             {:ok, locale} <- locale(other) do
          path = interpolate_params(other.path, params)
          Map.put(mapping, locale, path)
        else
          _any ->
            mapping
        end
      end
    )
  end

  defp interpolate_params(path, params) do
    path
    |> String.split("/")
    |> Enum.map(fn
      ":" <> part = param ->
        params
        |> Map.get(part, param)
        |> to_string()

      part ->
        part
    end)
    |> Enum.join("/")
  end

  @doc """
  Returns the equivalent localized path for the given path and locale.

  If the path is not found, it returns `nil`.

  ## Examples

  In the router:

      scope "/", MyAppWeb do
        get "/about", PageController, :index, metadata("en")
        get "/it/chi-siamo", PageController, :index, metadata("it")
      end

      > PhoenixMultilingual.Routes.localized_path(MyAppWeb.Router, "/about", "it")
      "/it/chi-siamo"
  """
  def localized_path(router, path, locale) do
    with {:ok, info} <- route_info(router, path),
         {:ok, route} <- find_route(router, info),
         {:ok, localized} <- find_localized_route(router, route, locale) do
      interpolate_params(localized.path, info.path_params)
    else
      _any ->
        nil
    end
  end

  defp find_localized_route(router, route, locale) do
    found =
      router
      |> Phoenix.Router.routes()
      |> Enum.find(fn other ->
        case locale(other) do
          {:ok, ^locale} ->
            same_view?(route, other)

          _any ->
            false
        end
      end)

    case found do
      nil ->
        {:error, :not_found}

      found ->
        found
        |> Map.take(Route.attrs())
        |> then(&{:ok, struct!(Route, &1)})
    end
  end

  defp same_view?(%{verb: verb_1}, _route_2) when verb_1 != :get, do: false
  defp same_view?(_route_1, %{verb: verb_2}) when verb_2 != :get, do: false

  defp same_view?(
         %{plug: Phoenix.LiveView.Plug} = route_1,
         %{plug: Phoenix.LiveView.Plug} = route_2
       ) do
    with :ok <- same_live_view_module?(route_1, route_2),
         true <- route_1.helper == route_2.helper,
         :ok <- same_view_name?(route_1, route_2) do
      true
    else
      _any ->
        false
    end
  end

  defp same_view?(%{plug: Phoenix.LiveView.Plug}, _route_2), do: false
  defp same_view?(_route_1, %{plug: Phoenix.LiveView.Plug}), do: false

  defp same_view?(route_1, route_2) do
    with true <- route_1.plug == route_2.plug,
         true <- route_1.helper == route_2.helper,
         :ok <- same_view_name?(route_1, route_2) do
      true
    else
      _any ->
        false
    end
  end

  defp same_live_view_module?(route_1, route_2) do
    with {:ok, module_1} <- live_view_module(route_1),
         {:ok, module_2} <- live_view_module(route_2),
         true <- module_1 == module_2 do
      :ok
    else
      _any ->
        {:error, :different_live_views}
    end
  end

  defp same_view_name?(route_1, route_2) do
    view_name_1 = view_name(route_1)
    view_name_2 = view_name(route_2)

    if view_name_1 == view_name_2 do
      :ok
    else
      {:error, :different_views}
    end
  end

  def view_name(route) do
    view_override(route) || route.plug_opts
  end

  @doc """
  Creates locale metadata for multilingual routes.

  ## Examples

      iex> PhoenixMultilingual.Routes.metadata("it")
      [metadata: %{multilingual: %PhoenixMultilingual.Metadata{locale: "it"}}]
  """
  def metadata(locale) do
    [metadata: %{multilingual: Metadata.new(locale)}]
  end

  @doc """
  Creates locale and view metadata for multilingual routes.

  ## Examples

      iex> PhoenixMultilingual.Routes.metadata(:about, "it")
      [metadata: %{multilingual: %PhoenixMultilingual.Metadata{view_override: :about, locale: "it"}}]
  """
  def metadata(view_override, locale) do
    [metadata: %{multilingual: Metadata.new(view_override, locale)}]
  end

  defp live_view_module(%{
         plug: Phoenix.LiveView.Plug,
         metadata: %{phoenix_live_view: {module, _action, _router_action, _opts}}
       }) do
    {:ok, module}
  end

  defp live_view_module(_other) do
    {:error, :not_live_view}
  end

  @doc """
  Returns the locale from the metadata of the route which provides
  the requested path.
  """
  def path_locale(router, path) do
    with {:ok, info} <- route_info(router, path),
         {:ok, route} <- find_route(router, info),
         {:ok, locale} <- locale(route) do
      locale
    else
      _error ->
        nil
    end
  end

  defp route_info(router, path) do
    case Phoenix.Router.route_info(router, "GET", path, nil) do
      :error ->
        {:error, :not_found}

      info ->
        info
        |> Map.take(RouteInfo.attrs())
        |> then(&{:ok, struct!(RouteInfo, &1)})
    end
  end

  defp find_route(router, %RouteInfo{} = info) do
    route =
      router
      |> Phoenix.Router.routes()
      |> Enum.find(&(&1.path == info.route))

    if route do
      route
      |> Map.take(Route.attrs())
      |> then(&{:ok, struct!(Route, &1)})
    else
      {:error, :not_found}
    end
  end

  def locale(%Route{} = route) do
    case get_in(route.metadata, [:multilingual, Access.key(:locale)]) do
      nil -> {:error, :no_locale}
      locale -> {:ok, locale}
    end
  end

  def locale(route) do
    case get_in(route, [:metadata, :multilingual, Access.key(:locale)]) do
      nil -> {:error, :no_locale}
      locale -> {:ok, locale}
    end
  end

  defp view_override(%Route{} = route) do
    get_in(route.metadata, [:multilingual, Access.key(:view_override)]) || route.plug_opts
  end

  defp view_override(route) do
    get_in(route, [:metadata, :multilingual, Access.key(:view_override)]) || route.plug_opts
  end
end
