defmodule PhoenixMultilingual.ComponentsTest do
  use ExUnit.Case

  import PhoenixMultilingual.Components

  describe "rel_links/1" do
    test "renders a list of rel links" do
      rels = [{"canonical", "en", "/about"}, {"alternate", "it", "/it/chi-siamo"}]

      result =
        rel_links(%{rels: rels})
        |> Phoenix.HTML.Safe.to_iodata()
        |> to_string()

      expected =
        ~s"""
        \n  \n    <link rel="canonical" href="/about">\n  
        \n  \n    <link rel="alternate" hreflang="it" href="/it/chi-siamo">\n  
        """

      assert result == expected
    end
  end
end
