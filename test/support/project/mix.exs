defmodule TestProject.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :test_project,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: [:lib],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TestProject.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:multilingual, ">= 0.0.0", path: "../../.."},
      {:phoenix, ">= 0.0.0"},
      {:phoenix_live_view, ">= 0.0.0"}
    ]
  end
end
