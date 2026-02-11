defmodule PhoenixMultilingual.Routes.Route do
  @moduledoc """
  A struct to hold route information returned by Phoenix.Router.routes/1.

  This struct only carries data from the Router.
  """
  @attrs [:verb, :path, :plug, :plug_opts, :helper, :metadata]
  @enforce_keys @attrs
  defstruct @attrs

  def attrs(), do: @attrs
end
