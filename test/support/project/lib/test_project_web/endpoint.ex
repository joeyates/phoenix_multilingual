defmodule TestProjectWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :test_project

  plug(TestProjectWeb.Router)
end
