defmodule Mix.Tasks.Multilingual.Routes do
  use Mix.Task

  alias PhoenixMultilingual.Routes

  @shortdoc "Shows a table of routes, grouped by view, with locales as columns"
  def run(_args) do
    Mix.Task.run("compile", [])
    base = Mix.Phoenix.base()
    router = Module.concat(["#{base}Web", "Router"])

    {localized_groups, _other} =
      router
      |> Phoenix.Router.routes()
      |> Enum.reduce({%{}, []}, fn route, {localized, other} ->
        case Routes.locale(route) do
          {:ok, locale} ->
            view = {route.plug, route.helper, route.plug_opts}

            localized =
              Map.update(localized, view, %{locale => route}, &Map.put(&1, locale, route))

            {localized, other}

          {:error, _} ->
            {localized, [route | other]}
        end
      end)

    locales =
      localized_groups
      |> Enum.reduce(%{}, fn {_view, routes}, acc ->
        routes
        |> Map.keys()
        |> Enum.reduce(acc, &Map.put(&2, &1, nil))
      end)
      |> Map.keys()

    headings = ["method", "module", "view"] ++ locales

    rows =
      localized_groups
      |> Enum.map(fn {{plug, _helper, plug_opts}, routes} ->
        common_columns =
          if plug == Phoenix.LiveView.Plug do
            route = hd(Map.values(routes))
            {module, action, _, _} = route.metadata.phoenix_live_view
            ["live", Macro.to_string(module), ":#{action}"]
          else
            ["get", Macro.to_string(plug), ":#{plug_opts}"]
          end

        locale_columns =
          Enum.map(locales, fn locale ->
            view = routes[locale]
            if view, do: view.path, else: "-"
          end)

        common_columns ++ locale_columns
      end)

    seed = Enum.map(headings, &String.length/1)

    column_widths =
      rows
      |> Enum.reduce(seed, fn row, acc ->
        Enum.zip(row, acc)
        |> Enum.map(fn {cell, acc} ->
          cell
          |> String.length()
          |> max(acc)
        end)
      end)

    [headings | rows]
    |> Enum.each(fn row ->
      row
      |> Enum.zip(column_widths)
      |> Enum.map(fn {cell, width} ->
        cell
        |> String.pad_trailing(width)
      end)
      |> Enum.join("  ")
      |> IO.puts()
    end)
  end
end
