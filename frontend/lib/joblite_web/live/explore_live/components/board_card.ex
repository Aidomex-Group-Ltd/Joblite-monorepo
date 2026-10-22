defmodule JobliteWeb.ExploreLive.Components.BoardCard do
  @moduledoc """
  One board of the job board directory.

  The card gives the reader a short description of what the board offers. The
  import permission, attribution rules, coverage checks and synchronization
  metadata stay internal. A board is always an outbound link; the card never
  presents imported listings as Joblite's own postings.
  """
  use Phoenix.Component

  attr(:board, :map, required: true)
  attr(:saved, :boolean, default: false)
  attr(:dismissed, :boolean, default: false)
  attr(:id_prefix, :string, default: "board")

  def board_card(assigns) do
    ~H"""
    <article class="jf-board" id={"#{@id_prefix}-#{@board.slug}"} data-board={@board.slug}>
      <header class="jf-board-head">
        <div class="jf-board-title">
          <h2>{@board.name}</h2>
          <p class="jf-board-host">{@board.url}</p>
        </div>
        <span :if={@board.remote_summary} class={["jf-board-mode", @board.status_tone]}>
          {@board.remote_summary}
        </span>
      </header>

      <p class="jf-board-note">{@board.description}</p>

      <div class="jf-board-actions">
        <a class="jf-board-open" href={@board.url} target="_blank" rel="noopener noreferrer">
          Visit job board<span class="jf-sr-only"> (opens in a new tab)</span>
        </a>
        <button
          :if={@dismissed}
          type="button"
          phx-click="boards:revisit"
          phx-value-id={@board.id}
        >Bring back</button>
        <button
          :if={@saved and not @dismissed}
          type="button"
          phx-click="boards:unsave"
          phx-value-id={@board.id}
        >Saved · remove</button>
        <button
          :if={!@saved and not @dismissed}
          type="button"
          phx-click="boards:save"
          phx-value-id={@board.id}
        >Save board</button>
      </div>
    </article>
    """
  end
end
