defmodule TestProject.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [TestProjectWeb.Endpoint]
    opts = [strategy: :one_for_one, name: TestProject.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
