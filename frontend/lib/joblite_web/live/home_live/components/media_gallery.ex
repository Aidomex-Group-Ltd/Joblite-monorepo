defmodule JobliteWeb.HomeLive.Components.MediaGallery do
  @moduledoc "Thumbnail buttons only. Full video elements are created by the viewer hook."
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.Icons

  attr(:media, :list, required: true)
  attr(:post_id, :string, required: true)

  def gallery(assigns) do
    ~H"""
    <div
      :if={@media != []}
      class={["jf-media-grid", length(@media) > 1 && "multiple"]}
      data-feed-gallery
    >
      <button
        :for={{media, index} <- Enum.with_index(@media)}
        type="button"
        id={"media-#{@post_id}-#{index}"}
        class="jf-thumb"
        data-feed-action="open-media"
        data-media-id={media.id}
        data-media-kind={media.kind}
        data-media-local={to_string(media.local)}
        data-media-source={media.source}
        data-media-thumbnail={media.thumbnail}
        data-media-alt={media.alt}
        aria-label={"Expand #{media.kind}: #{media.alt}"}
      >
        <img
          :if={not media.local}
          src={media.thumbnail || media.source}
          alt={media.alt}
          loading="lazy"
          decoding="async"
        />
        <img :if={media.local} data-local-thumbnail={media.id} alt={media.alt} hidden />
        <span :if={media.local} class="jf-local-state" data-local-state={media.id}>Preparing preview…</span>
        <span :if={media.kind == "video"} class="jf-play"><span><.icon name="play" /></span></span>
        <span :if={media.kind == "video"} class="jf-duration">{media.duration || "Video"}</span>
        <span class="jf-expand"><.icon name="expand" /></span>
      </button>
    </div>
    """
  end
end
