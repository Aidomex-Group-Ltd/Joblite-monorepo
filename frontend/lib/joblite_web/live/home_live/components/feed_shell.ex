defmodule JobliteWeb.HomeLive.Components.FeedShell do
  @moduledoc "Feed chrome, navigation and empty states."
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.Icons

  def header(assigns) do
    ~H"""
    <header class="jf-header">
      <a class="jf-logo" href="/" aria-label="Joblite home"><span>j</span>joblite<b>.</b></a>
      <div>
        <small>PREVIEW</small><button
          type="button"
          class="jf-icon-button"
          data-feed-action="compose"
          aria-label="Create a post"
        ><.icon name="edit" /></button>
      </div>
    </header>
    """
  end

  attr(:page, :string, required: true)
  attr(:tab, :string, required: true)

  def tabs(assigns) do
    ~H"""
    <div class="jf-tabs" aria-label="Feed selection">
      <button
        :for={
          {tab, label} <- [{"foryou", "For you"}, {"following", "Following"}, {"hiring", "Hiring"}]
        }
        id={"tab-#{tab}"}
        type="button"
        phx-click="feed:tab"
        phx-value-tab={tab}
        aria-pressed={to_string(@page == "feed" and @tab == tab)}
      >{label}</button>
    </div>
    """
  end

  attr(:page, :string, required: true)

  def desktop_nav(assigns) do
    ~H"""
    <aside class="jf-rail jf-rail-left" aria-label="Desktop navigation">
      <a class="jf-rail-logo" href="/" aria-label="Joblite home">
        <span>j</span>joblite<b>.</b>
      </a>

      <nav class="jf-rail-nav">
        <button
          :for={
            {page, label} <- [
              {"feed", "Feed"},
              {"saved", "Saved posts"},
              {"mine", "My posts"}
            ]
          }
          id={"rail-nav-#{page}"}
          type="button"
          phx-click="feed:page"
          phx-value-page={page}
          aria-current={if @page == page, do: "page", else: nil}
        >{label}</button>
        <a href="/explore">Explore boards</a>
        <a href="/explore/saved">Saved boards</a>
        <a href="/account">Account</a>
      </nav>

      <p class="jf-rail-note">
        A preview workspace for candidates and the people who hire them.
      </p>
    </aside>
    """
  end

  attr(:page, :string, required: true)

  def bottom_nav(assigns) do
    ~H"""
    <nav class="jf-bottom-nav" aria-label="Main navigation">
      <button
        :for={
          {page, label, icon} <- [
            {"feed", "Feed", "home"},
            {"saved", "Saved", "bookmark"},
            {"mine", "My posts", "user"}
          ]
        }
        id={"nav-#{page}"}
        type="button"
        phx-click="feed:page"
        phx-value-page={page}
        aria-current={if @page == page, do: "page", else: nil}
      ><.icon name={icon} /><span>{label}</span></button>
      <a class="jf-nav-link" id="nav-explore" href="/explore">
        <.icon name="compass" /><span>Explore boards</span>
      </a>
      <button type="button" data-feed-action="compose"><.icon name="plus" /><span>Create</span></button>
    </nav>
    """
  end

  def quick_compose(assigns) do
    ~H"""
    <div class="jf-quick-compose">
      <span class="jf-avatar" aria-hidden="true">Y</span>
      <button type="button" data-feed-action="compose">Show the work. Tell your story.</button>
      <button
        type="button"
        class="jf-icon-button"
        data-feed-action="compose"
        aria-label="Add photos or a video"
      ><.icon name="image" /></button>
    </div>
    """
  end

  attr(:page, :string, required: true)

  def empty_state(assigns) do
    ~H"""
    <section id="feed-empty" class="jf-empty">
      <h2>{if @page == "saved", do: "Good things, kept close.", else: "Your story starts here."}</h2>
      <p>
        {if @page == "saved",
          do: "Save a post to find it here.",
          else: "Share a video, photos, or a few words in your preview feed."}
      </p>
    </section>
    """
  end
end
