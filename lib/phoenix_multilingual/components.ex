if Code.ensure_loaded?(Phoenix.Component) do
  defmodule PhoenixMultilingual.Components do
    use Phoenix.Component

    @doc """
    Create a list of rel links for the current page.
    """
    attr(:rels, :list)

    def rel_links(assigns) do
      ~H"""
      <%= for {rel, lang, url} <- @rels do %>
        <%= if rel == "canonical" do %>
          <link rel={rel} href={url} />
        <% else %>
          <link rel={rel} hreflang={lang} href={url} />
        <% end %>
      <% end %>
      """
    end
  end
end
