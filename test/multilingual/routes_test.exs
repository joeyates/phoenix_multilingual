defmodule PhoenixMultilingual.RoutesTest do
  use ExUnit.Case

  import PhoenixMultilingual.Routes

  alias TestProjectWeb.Router

  doctest PhoenixMultilingual.Routes

  setup do
    conn = %Plug.Conn{private: %{phoenix_router: Router}}

    {:ok, conn: conn}
  end

  describe "build_page_mapping/2" do
    test "returns a mapping of locales to paths for a path" do
      {:ok, mapping} = build_page_mapping(Router, "/about")
      assert mapping == %{"en" => "/about", "it" => "/it/chi-siamo"}
    end

    test "when the route has parameters, builds paths correctly" do
      {:ok, mapping} = build_page_mapping(Router, "/contacts/fred")
      assert mapping == %{"en" => "/contacts/fred", "it" => "/it/contatti/fred"}
    end

    test "returns a mapping of locales to paths for a path, when plug_opts are different" do
      {:ok, mapping} = build_page_mapping(Router, "/projects")
      assert mapping == %{"en" => "/projects", "it" => "/it/progetti"}
    end

    test "returns an error tuple when the path doesn't exist" do
      assert {:error, :not_found} == build_page_mapping(Router, "/doesnt_exist")
    end

    test "returns an error tuple when the path is not localized" do
      assert {:error, :not_localized} == build_page_mapping(Router, "/monolingual")
    end

    test "accepts a Plug.Conn", %{conn: conn} do
      {:ok, mapping} = build_page_mapping(conn, "/about")
      assert mapping == %{"en" => "/about", "it" => "/it/chi-siamo"}
    end
  end

  describe "localized_path/3" do
    test "returns the localized path" do
      assert localized_path(Router, "/about", "it") == "/it/chi-siamo"
    end

    test "returns an error tuple when the path doesn't exist" do
      assert localized_path(Router, "/doesnt_exist", "it") == nil
    end

    test "returns an error tuple when the path is not localized" do
      assert localized_path(Router, "/monolingual", "it") == nil
    end

    test "returns an error tuple when the path is not localized for the requested locale" do
      assert localized_path(Router, "/about", "fr") == nil
    end
  end

  describe "path_locale/2" do
    test "returns a path's locale" do
      assert path_locale(Router, "/about") == "en"
    end

    test "returns nil when the path is not found" do
      assert path_locale(Router, "/doesnt_exist") == nil
    end
  end
end
