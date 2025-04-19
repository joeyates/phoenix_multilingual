defmodule Multilingual.Plugs.RedirectIncoming do
  @moduledoc """
  Redirects incoming requests to the user's preferred language.

  Use this plug in your router pipeline to redirect incoming requests
  to the user's preferred language, as indicated by the "Accept-Language"
  header.

  This plug should be preceded by another plug that actually does the
  fetching and parsing of the "Accept-Language" header, such as
  `Cldr.Plug.AcceptLanguage`.

  Two options are required:

  * `:accept_locale_source` - the module that provides the user's preferred
    language. Currently, only `Cldr` is supported,
  * `:nearest_known` - a function that returns the nearest known locale
    to the user's preferred locale.

  ## Example

      pipeline :browser do
        ...
        plug Cldr.Plug.AcceptLanguage, cldr_backend: MyApp.Cldr
        plug RedirectIncoming,
          accept_locale_source: Cldr,
          nearest_known: &MyApp.nearest_known/1
        ...
      end
  """

  @attrs [:accept_locale_source, :nearest_known]
  @enforce_keys @attrs
  defstruct @attrs

  alias Multilingual.Routes
  alias Multilingual.View

  @supported_accept_locale_sources [
    Cldr
  ]

  def init(opts) do
    {accept_locale_source, opts} = Keyword.pop!(opts, :accept_locale_source)
    {nearest_known, []} = Keyword.pop!(opts, :nearest_known)

    if accept_locale_source not in @supported_accept_locale_sources do
      message =
        "unsupported accept_locale_source: #{inspect(accept_locale_source)}. " <>
          "Supported values are: #{inspect(@supported_accept_locale_sources)}."

      raise ArgumentError, message
    end

    %__MODULE__{
      accept_locale_source: accept_locale_source,
      nearest_known: nearest_known
    }
  end

  @doc """
  If a request has a "Referer" that is not the current host,
  we may want to redirect to the user's preferred language,
  as indicated by the "Accept-Language" header.
  """
  def call(conn, %__MODULE__{} = opts) do
    with {:ok, referer_host} <- referer_host(conn),
         false <- same_host(conn, referer_host),
         {:ok, original_accept_locale} <- accept_locale(conn, opts),
         {:ok, known_accept_locale} <- nearest_known(original_accept_locale, opts),
         {:ok, page_locale} <- get_view_locale(conn),
         false <- known_accept_locale == page_locale,
         {:ok, locale_path} <- locale_path(conn, known_accept_locale),
         false <- locale_path == conn.request_path do
      Phoenix.Controller.redirect(conn, to: locale_path)
    else
      _any ->
        conn
    end
  end

  defp accept_locale(conn, %__MODULE__{accept_locale_source: Cldr}) do
    case conn.private[:cldr_locale] do
      nil ->
        {:error, :no_accept_locale}

      locale when is_binary(locale) ->
        {:ok, locale}

      %Cldr.LanguageTag{} = locale ->
        {:ok, to_string(locale)}
    end
  end

  defp get_view_locale(conn) do
    case View.get_key(conn, :locale) do
      nil ->
        {:error, :no_view_locale}

      locale ->
        {:ok, locale}
    end
  end

  defp locale_path(conn, locale) do
    case Routes.localized_path(conn.router, conn.request_path, locale) do
      nil ->
        {:error, :no_localized_path}

      path ->
        {:ok, path}
    end
  end

  def nearest_known(locale, %__MODULE__{nearest_known: nearest_known}) do
    case nearest_known.(locale) do
      nil ->
        {:error, :unknown_locale}

      nearest_locale ->
        {:ok, nearest_locale}
    end
  end

  defp referer_host(conn) do
    case Plug.Conn.get_req_header(conn, "referer") do
      [] ->
        {:error, :no_referer}

      [referer] ->
        uri = URI.parse(referer)
        {:ok, uri.host}
    end
  end

  defp same_host(conn, host) do
    conn.host == host
  end
end
