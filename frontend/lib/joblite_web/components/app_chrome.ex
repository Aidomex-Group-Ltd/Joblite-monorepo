defmodule JobliteWeb.Components.AppChrome do
  @moduledoc """
  Desktop navigation and the secondary rail shared by the directory screens.

  The rails are supplemental: every destination remains reachable through the
  mobile navigation and the site header. They are hidden below the desktop
  breakpoint so the feed keeps a single readable column on small screens.
  """
  use Phoenix.Component

  attr(:current, :string, required: true)

  def desktop_nav(assigns) do
    ~H"""
    <aside class="jf-rail jf-rail-left" aria-label="Desktop navigation">
      <a class="jf-rail-logo" href="/" aria-label="Joblite home">
        <span>j</span>joblite<b>.</b>
      </a>

      <nav class="jf-rail-nav">
        <a href="/" aria-current={if @current == "feed", do: "page", else: nil}>
          Feed
        </a>
        <a href="/explore" aria-current={if @current == "explore", do: "page", else: nil}>
          Explore boards
        </a>
        <a href="/explore/saved" aria-current={if @current == "saved", do: "page", else: nil}>
          Saved boards
        </a>
        <a href="/account" aria-current={if @current == "account", do: "page", else: nil}>
          Account
        </a>
      </nav>

      <p class="jf-rail-note">
        A preview workspace for candidates and the people who hire them.
      </p>
    </aside>
    """
  end

  def desktop_rail(assigns) do
    ~H"""
    <aside class="jf-rail jf-rail-right" aria-label="About Joblite">
      <section class="jf-rail-card">
        <h2>Find your next opportunity</h2>
        <p>
          Browse job boards for remote and local roles, then visit the original site to
          learn more and apply.
        </p>
      </section>

      <section class="jf-rail-card">
        <h2>Keep what matters</h2>
        <p>
          Save a board to keep it close, or hide one to keep it out of the feed rotation.
          The lists belong to your account.
        </p>
        <a class="jf-rail-link" href="/explore/saved">Open saved boards</a>
      </section>
    </aside>
    """
  end
end
