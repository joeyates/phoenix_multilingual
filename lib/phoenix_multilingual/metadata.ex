defmodule PhoenixMultilingual.Metadata do
  @moduledoc """
  A struct to hold multilingual metadata for a route.
  """

  @enforce_keys [:locale]
  defstruct [:locale, :view_override]

  @type t :: %__MODULE__{
          locale: String.t(),
          view_override: atom() | nil
        }

  def new(locale) when is_binary(locale) do
    %__MODULE__{locale: locale}
  end

  def new(view_name, locale) when is_atom(view_name) and is_binary(locale) do
    %__MODULE__{locale: locale, view_override: view_name}
  end

  def new(view_name, locale) when is_binary(view_name) do
    view_atom = String.to_existing_atom(view_name)
    new(view_atom, locale)
  end

  def new(view_name, locale) when is_atom(locale) do
    locale_string = Atom.to_string(locale)
    new(view_name, locale_string)
  end
end
