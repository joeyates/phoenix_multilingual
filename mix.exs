defmodule PhoenixMultilingual.MixProject do
  use Mix.Project

  @app :phoenix_multilingual

  def project do
    [
      app: @app,
      version: "0.1.11",
      elixir: "~> 1.17",
      description:
        "Simplify handling localized routes in Elixir Phoenix applications, with and without LiveView",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr, ">= 2.39.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:gettext, "~> 0.18", optional: true},
      {:jason, ">= 1.4.1"},
      {:phoenix, ">= 1.7.10"},
      {:phoenix_live_view, ">= 0.20.1", optional: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support/project/lib/test_project_web"]
  defp elixirc_paths(_env), do: ["lib"]

  defp package do
    %{
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/joeyates/phoenix_multilingual"
      },
      maintainers: ["Joe Yates"]
    }
  end
end
