defmodule PhoenixMultilingual.Plugs.PutGettextLocaleTest do
  use ExUnit.Case, async: true

  import PhoenixMultilingual.Plugs.PutGettextLocale

  describe "call/2" do
    setup do
      previous_locale = Gettext.get_locale()
      Gettext.put_locale("zh")

      on_exit(fn ->
        Gettext.put_locale(previous_locale)
      end)
    end

    test "sets the gettext locale" do
      view = %PhoenixMultilingual.View{locale: "fr", path: "/"}
      conn = %Plug.Conn{private: %{multilingual: view}}

      call(conn, %{})

      assert Gettext.get_locale() == "fr"
    end

    test "when the locale is not set, it throws an error" do
      assert_raise PhoenixMultilingual.MissingViewDataInConnError, fn ->
        call(%Plug.Conn{}, nil)
      end
    end
  end
end
