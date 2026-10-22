defmodule JobliteWeb.HomeLive.Components.FeedPost do
  @moduledoc "One feed post, with media delegated to the gallery component."
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.Icons
  import JobliteWeb.HomeLive.Components.MediaGallery

  attr(:post, :map, required: true)
  attr(:liked, :boolean, required: true)
  attr(:saved, :boolean, required: true)

  def post(assigns) do
    ~H"""
    <article
      id={"post-#{@post.id}"}
      class="jf-post"
      data-feed-post
      data-author={@post.author}
      data-handle={@post.handle}
      data-body={@post.body}
    >
      <span class={["jf-avatar", @post.tone]} aria-hidden="true">{@post.initial}</span>
      <div class="jf-post-main">
        <div class="jf-author">
          <strong>{@post.author}</strong><span>{@post.handle}</span><small>{@post.time}</small>
        </div>
        <p :if={@post.role} class="jf-role-label"><.icon name="briefcase" /> Hiring · Design</p>
        <p class="jf-post-text">{@post.body}</p>
        <.gallery media={@post.media} post_id={@post.id} />
        <div :if={@post.role} class="jf-role">
          <strong>{@post.role.title}</strong><small>{@post.role.arrangement}</small>
        </div>
        <div class="jf-post-actions">
          <button type="button" data-feed-action="reply" aria-label={"Reply to #{@post.author}"}><.icon name="reply" /><span>Reply</span></button>
          <button
            type="button"
            id={"like-#{@post.id}"}
            class={@liked && "is-selected"}
            phx-click="feed:like"
            phx-value-id={@post.id}
            aria-label={"Like post from #{@post.author}"}
            aria-pressed={to_string(@liked)}
          ><.icon name="heart" /></button>
          <button
            type="button"
            id={"save-#{@post.id}"}
            class={@saved && "is-selected"}
            phx-click="feed:save"
            phx-value-id={@post.id}
            aria-label={"Save post from #{@post.author}"}
            aria-pressed={to_string(@saved)}
          ><.icon name="bookmark" /></button>
        </div>
      </div>
    </article>
    """
  end
end
