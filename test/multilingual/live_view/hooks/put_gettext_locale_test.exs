defmodule PhoenixMultilingual.Hooks.PutGettextLocaleTest do
  use ExUnit.Case

  import PhoenixMultilingual.Hooks.PutGettextLocale
  import Phoenix.LiveView

  defp optionally_add_multilingual_view(socket, %{multilingual_view: false}), do: socket

  defp optionally_add_multilingual_view(socket, _context) do
    put_private(socket, :multilingual, %PhoenixMultilingual.View{path: "/my_live", locale: "fr"})
  end

  describe "on_mount/4" do
    setup context do
      previous_locale = Gettext.get_locale()
      Gettext.put_locale("zh")

      on_exit(fn ->
        Gettext.put_locale(previous_locale)
      end)

      socket = %Phoenix.LiveView.Socket{router: Router}

      private = Map.put(socket.private, :lifecycle, %{handle_params: []})

      socket =
        %{socket | private: private}
        |> optionally_add_multilingual_view(context)

      {:ok, socket: socket}
    end

    test "attaches the put_locale hook", %{socket: socket} do
      {_, socket} = on_mount(:default, nil, nil, socket)

      assert [%{function: _fn, id: :multilingual_put_locale}] =
               socket.private.lifecycle.handle_params
    end

    test "returns {:cont, socket}", %{socket: socket} do
      {:cont, _socket} = on_mount(:default, nil, nil, socket)
    end

    test "the hook puts the Gettext locale", %{socket: socket} do
      {_, socket} = on_mount(:default, nil, nil, socket)

      hook = hd(socket.private.lifecycle.handle_params)
      {_, _socket} = hook.function.([], "http://example.com/about", socket)

      assert Gettext.get_locale() == "fr"
    end

    @tag multilingual_view: false
    test "the hook fails if the view information is not stored in the socket's private data", %{
      socket: socket
    } do
      {_, socket} = on_mount(:default, nil, nil, socket)

      assert_raise PhoenixMultilingual.MissingViewDataInSocketError, fn ->
        hook = hd(socket.private.lifecycle.handle_params)
        {_, _socket} = hook.function.([], "http://example.com/about", socket)
      end
    end
  end
end
