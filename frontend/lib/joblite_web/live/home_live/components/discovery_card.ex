defmodule JobliteWeb.HomeLive.Components.DiscoveryCard do
  @moduledoc """
  One job board discovery card in the feed.

  The card is labelled directory content: it names a board from the directory
  and describes what the reader can find there. Import permissions, coverage
  checks and synchronization details stay internal. It never looks like a post
  and never presents an imported listing as a Joblite posting. A listing that
  was imported links to the original listing, so the reader always reaches the
  source and sees its credit.
  """
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.Icons

  attr(:card, :map, required: true)
  attr(:signed_in, :boolean, default: false)

  def discovery_card(assigns) do
    ~H"""
    <aside id="discovery-card" class="jf-discovery" data-board={@card.slug}>
      <p class="jf-discovery-label"><.icon name="compass" /> Job board directory</p>
      <div class="jf-discovery-head">
        <h2>{@card.name}</h2>
        <span :if={@card.remote_summary} class={["jf-board-mode", @card.status_tone]}>
          {@card.remote_summary}
        </span>
      </div>
      <p class="jf-discovery-text">{@card.description}</p>

      <p :if={@card.listing} class="jf-discovery-listing">
        Latest listing:
        <a href={@card.listing.canonical_url} target="_blank" rel="noopener noreferrer">
          {@card.listing.title}<span class="jf-sr-only"> (opens in a new tab)</span>
        </a>
        · {@card.listing.attribution}
      </p>

      <div class="jf-discovery-actions">
        <a class="jf-board-open" href={@card.url} target="_blank" rel="noopener noreferrer">
          Visit job board<span class="jf-sr-only"> (opens in a new tab)</span>
        </a>
        <button
          :if={@signed_in}
          type="button"
          phx-click="boards:save"
          phx-value-id={@card.id}
        >Save</button>
        <a :if={!@signed_in} class="jf-discovery-login" href="/users/log-in">Log in to save</a>
        <button type="button" phx-click="boards:dismiss" phx-value-id={@card.id}>Not interested</button>
      </div>
    </aside>
    """
  end
end
