defmodule Multilingual.Routes do
  defmodule RouteInfo do
    @moduledoc """
    A struct to hold route information supplied by Phoenix.Router.route_info/4.

    This struct is specific to a path and has parameter infomation.
    """
    @attrs [:plug, :route, :plug_opts, :path_params]
    @enforce_keys @attrs
    defstruct @attrs

    def attrs, do: @attrs
  end

  defmodule Route do
    @moduledoc """
    A struct to hold route information returned by Phoenix.Router.routes/1.

    This struct only carries data from the Router.
    """
    @attrs [:verb, :path, :plug, :plug_opts, :helper, :metadata]
    @enforce_keys @attrs
    defstruct @attrs

    def attrs, do: @attrs
  end

  @doc """
  Builds a mapping of locales to paths for the current page.

  ## Examples

  In the router:

      scope "/", MyAppWeb do
        get "/about", PageController, :index, metadata("en")
        get "/it/chi-siamo", PageController, :index, metadata("it")
      end

      > Multilingual.Routes.build_page_mapping(Router, "/about")
      {:ok, %{"en" => "/about", "it" => "/it/chi-siamo"}}

  The result can be used to create a language switcher in the view.

      <% locales = ["en", "it"] %>
      <% locale = Multilingual.View.fetch_key(@conn, :locale) %>
      <% path = Multilingual.View.fetch_key(@conn, :route) %>
      <% {:ok, mapping} = Multilingual.Routes.build_page_mapping(@conn, path) %>
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
    Phoenix.Controller.router_module(conn)
    |> build_page_mapping(path)
  end

  def build_page_mapping(router, path) do
    with {:ok, info} <- route_info(router, path),
         {:ok, route} <- find_route(router, info),
         :ok <- is_localized?(route) do
      build_route_mapping(router, route, info.path_params)
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
    Phoenix.Router.routes(router)
    |> Enum.reduce(
      %{},
      fn other, mapping ->
        with :get <- other.verb,
             true <- same_view(route, other),
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
      <<":", part::binary>> = param ->
        Map.get(params, part, param)
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

      > Multilingual.Routes.localized_path(MyAppWeb.Router, "/about", "it")
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
      Phoenix.Router.routes(router)
      |> Enum.find(fn other ->
        case locale(other) do
          {:ok, ^locale} ->
            same_view(route, other)

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

  defp same_view(route_1, route_2) do
    with true <- route_1.verb == route_2.verb,
         true <- route_1.plug == route_2.plug,
         view_1 = get_in(route_1.metadata, [:multilingual, :view]) || route_1.plug_opts,
         view_2 = get_in(route_2.metadata, [:multilingual, :view]) || route_2.plug_opts,
         true <- view_1 == view_2,
         true <- route_1.helper == route_2.helper do
      true
    else
      _any ->
        false
    end
  end

  @doc """
  Creates locale metadata for multilingual routes.

  ## Examples

      iex> Multilingual.Routes.metadata("it")
      [metadata: %{multilingual: %{locale: "it"}}]
  """
  def metadata(locale) do
    [metadata: %{multilingual: %{locale: locale}}]
  end

  @doc """
  Creates locale and view metadata for multilingual routes.

  ## Examples

      iex> Multilingual.Routes.metadata(:about, "it")
      [metadata: %{multilingual: %{view: :about, locale: "it"}}]
  """
  def metadata(view, locale) do
    [metadata: %{multilingual: %{view: view, locale: locale}}]
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
    case get_in(route.metadata, [:multilingual, :locale]) do
      nil -> {:error, :no_locale}
      locale -> {:ok, locale}
    end
  end

  def locale(route) do
    case get_in(route, [:metadata, :multilingual, :locale]) do
      nil -> {:error, :no_locale}
      locale -> {:ok, locale}
    end
  end
end
