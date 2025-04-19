defmodule PhoenixMultilingual.HTMLTest do
  use ExUnit.Case

  import PhoenixMultilingual.HTML
  alias PhoenixMultilingual.Test.Project.Router

  describe "get_rel_links/1" do
    defp iodata_to_string(iodata) do
      iodata
      |> Phoenix.HTML.Safe.to_iodata()
      |> to_string()
    end

    setup context do
      conn =
        Phoenix.ConnTest.build_conn()
        |> Map.put(:router, Router)
        |> Plug.Conn.put_private(:phoenix_router, Router)
        |> Plug.Conn.put_private(:phoenix_router_url, "http://example.com")
        |> Plug.Conn.put_private(:multilingual, %PhoenixMultilingual.View{
          path: context.path,
          locale: "en"
        })

      {:ok, conn: conn}
    end

    @tag path: "/about"
    test "returns rel links based on the router", %{conn: conn} do
      result = get_rel_links(conn) |> iodata_to_string()

      expected =
        "\n  \n    <link rel=\"canonical\" href=\"http://example.com/about\">\n  \n\n  \n    <link rel=\"alternate\" hreflang=\"it\" href=\"http://example.com/it/chi-siamo\">\n  \n"

      assert result == expected
    end

    @tag path: "/contacts/fred"
    test "when the route has parameters, build links correctly", %{conn: conn} do
      result = get_rel_links(conn) |> iodata_to_string()

      expected =
        "\n  \n    <link rel=\"canonical\" href=\"http://example.com/contacts/fred\">\n  \n\n  \n    <link rel=\"alternate\" hreflang=\"it\" href=\"http://example.com/it/contatti/fred\">\n  \n"

      assert result == expected
    end
  end
end
