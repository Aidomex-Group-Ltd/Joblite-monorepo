defmodule JobliteWeb.HomeLive.Components.FeedStream do
  @moduledoc """
  The feed stream.

  The stream holds the candidate posts and the job board discovery card. The
  card is placed after the employer posts, among the candidate posts, so it
  never reads as a post of its own.
  """
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.DiscoveryCard
  import JobliteWeb.HomeLive.Components.FeedPost

  attr(:items, :list, required: true)
  attr(:liked, :any, required: true)
  attr(:saved, :any, required: true)
  attr(:signed_in, :boolean, default: false)

  def feed_stream(assigns) do
    ~H"""
    <div id="feed-posts">
      <%= for item <- @items do %>
        <%= case item do %>
          <% {:post, post} -> %>
            <.post
              post={post}
              liked={MapSet.member?(@liked, post.id)}
              saved={MapSet.member?(@saved, post.id)}
            />
          <% {:discovery, card} -> %>
            <.discovery_card card={card} signed_in={@signed_in} />
        <% end %>
      <% end %>
    </div>
    """
  end
end
