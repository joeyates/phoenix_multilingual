defmodule PhoenixMultilingual.Plugs.RedirectIncomingTest do
  use ExUnit.Case, async: true

  import PhoenixMultilingual.Plugs.RedirectIncoming
  alias PhoenixMultilingual.Plugs.RedirectIncoming
  alias PhoenixMultilingual.View
  alias TestProjectWeb.Router

  defp build_conn(context) do
    Phoenix.ConnTest.build_conn()
    |> Map.put(:host, "example.com")
    |> Map.put(:router, Router)
    |> optionally_add_cldr_accept_locale(context)
    |> optionally_add_referer(context)
    |> optionally_add_multilingual_view(context)
    |> set_request_path(context)
  end

  defp set_request_path(conn, %{request_path: path}) when is_binary(path) do
    Map.put(conn, :request_path, path)
  end

  defp set_request_path(conn, _context) do
    Map.put(conn, :request_path, "/about")
  end

  defp optionally_add_cldr_accept_locale(conn, %{cldr_accept_locale: false}), do: conn

  defp optionally_add_cldr_accept_locale(conn, %{cldr_accept_locale: locale})
       when is_binary(locale) do
    Plug.Conn.put_private(conn, :cldr_locale, locale)
  end

  defp optionally_add_cldr_accept_locale(conn, _context) do
    Plug.Conn.put_private(conn, :cldr_locale, "it-IT")
  end

  defp optionally_add_multilingual_view(conn, %{multilingual_view: false}), do: conn

  defp optionally_add_multilingual_view(conn, _context) do
    Plug.Conn.put_private(conn, :multilingual, %View{path: "/about", locale: "en"})
  end

  defp optionally_add_referer(conn, %{referer: false}), do: conn

  defp optionally_add_referer(conn, %{referer: referer}) when is_binary(referer) do
    Plug.Conn.put_req_header(conn, "referer", referer)
  end

  defp optionally_add_referer(conn, _context) do
    Plug.Conn.put_req_header(conn, "referer", "http://other-site.com/about")
  end

  describe "init/1" do
    test "returns the source of accepted locales" do
      opts = [accept_locale_source: Cldr, nearest_known: fn _ -> nil end]
      assert %{accept_locale_source: Cldr} = init(opts)
    end

    test "returns the nearest known locale function" do
      nearest_known = fn _ -> nil end
      opts = [accept_locale_source: Cldr, nearest_known: nearest_known]
      assert %{nearest_known: ^nearest_known} = init(opts)
    end

    test "raises an error when the :accept_locale_source is not known" do
      opts = [accept_locale_source: SomeModule, nearest_known: fn _ -> nil end]

      assert_raise ArgumentError, ~r/unsupported accept_locale_source/, fn ->
        init(opts)
      end
    end

    test "raises an error when the :accept_locale_source is not provided" do
      assert_raise FunctionClauseError, fn ->
        init(%{nearest_known: fn _ -> nil end})
      end
    end

    test "raises an error when the :nearest_known is not provided" do
      assert_raise FunctionClauseError, fn ->
        init(%{accept_locale_source: Cldr})
      end
    end
  end

  describe "call/2" do
    setup context do
      opts = %RedirectIncoming{accept_locale_source: Cldr, nearest_known: fn _ -> "it" end}
      conn = build_conn(context)

      {:ok, opts: opts, conn: conn}
    end

    test "redirects to the user's preferred language", %{conn: conn, opts: opts} do
      assert %Plug.Conn{status: 302} = call(conn, opts)
    end

    @tag referer: false
    test "when there is no 'Referer' header, it does nothing", %{conn: conn, opts: opts} do
      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    @tag cldr_accept_locale: false
    test "when there is no accept locale set, it does nothing", %{conn: conn, opts: opts} do
      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    @tag referer: "https://example.com/foo"
    test "when the referer host is the same as the current host, it does nothing", %{
      conn: conn,
      opts: opts
    } do
      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    test "when there is no nearest known locale, it does nothing", %{conn: conn, opts: opts} do
      opts = Map.put(opts, :nearest_known, fn _accept_locale -> nil end)

      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    @tag multilingual_view: false
    test "when there is no multilingual page locale, it does nothing", %{conn: conn, opts: opts} do
      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    @tag cldr_accept_locale: "en-GB"
    test "when the known accept locale is the same as the page locale, it does nothing", %{
      conn: conn,
      opts: opts
    } do
      opts = Map.put(opts, :nearest_known, fn "en-GB" -> "en" end)

      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    @tag request_path: "/monolingual"
    test "when there is no localized route, it does nothing", %{conn: conn, opts: opts} do
      assert %Plug.Conn{status: nil} = call(conn, opts)
    end

    @tag request_path: "/it/chi-siamo"
    test "when the localized route is the same as the requested route, it does nothing", %{
      conn: conn,
      opts: opts
    } do
      assert %Plug.Conn{status: nil} = call(conn, opts)
    end
  end
end
