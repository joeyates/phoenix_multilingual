defmodule PhoenixMultilingual.Routes.RouteInfo do
  @moduledoc """
  A struct to hold route information supplied by Phoenix.Router.route_info/4.

  This struct is specific to a path and has parameter infomation.
  """

  @attrs [:plug, :route, :plug_opts, :path_params]
  @enforce_keys @attrs
  defstruct @attrs

  def attrs(), do: @attrs
end
