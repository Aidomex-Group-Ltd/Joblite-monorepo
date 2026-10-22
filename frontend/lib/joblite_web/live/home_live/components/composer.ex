defmodule JobliteWeb.HomeLive.Components.Composer do
  @moduledoc "Composer shell; file reading stays in a dedicated browser hook."
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.Icons

  attr(:uploads, :map, required: true)

  def composer(assigns) do
    ~H"""
    <dialog
      id="feed-composer"
      class="jf-dialog jf-composer"
      phx-hook="FeedComposer"
      aria-labelledby="composer-title"
    >
      <form
        id="feed-composer-form"
        data-composer-form
        phx-change="validate-media"
        phx-submit="submit-post"
      >
        <.live_file_input upload={@uploads.media} class="jf-sr-only" />
        <p :for={entry <- @uploads.media.entries} class="jf-sr-only">
          {entry.client_name} ({entry.progress}%)
        </p>
        <div id="composer-static" phx-update="ignore">
          <header class="jf-dialog-header">
            <button type="button" class="jf-icon-button" data-close aria-label="Close composer"><.icon name="left" /></button>
            <h2 id="composer-title">New post</h2><button
              type="submit"
              class="jf-pill"
              data-submit
              disabled
            >Post</button>
          </header>
          <div class="jf-composer-content">
            <p class="jf-writer">
              <span class="jf-avatar" aria-hidden="true">Y</span><strong>You<small>Sharing in your preview session</small></strong>
            </p>
            <label for="feed-body" class="jf-sr-only">Your post</label>
            <textarea
              id="feed-body"
              name="body"
              maxlength="600"
              rows="5"
              data-body
              placeholder="A role to share? A project you’re proud of? Tell your story…"
            ></textarea>
            <div class="jf-attach-grid" data-attachments></div>
            <div class="jf-compose-tools">
              <button type="button" data-add="image"><.icon name="image" />Photos</button>
              <button type="button" data-add="video"><.icon name="video" />Video</button><span data-character-count>0 / 600</span>
            </div>
            <input
              type="file"
              data-files="image"
              accept="image/jpeg,image/png,image/webp"
              multiple
              hidden
              aria-label="Choose photos"
            />
            <input
              type="file"
              data-files="video"
              accept="video/mp4,video/webm"
              hidden
              aria-label="Choose a video"
            />
            <p data-error class="jf-error" role="alert"></p>
            <p class="jf-local-note">
              Up to 4 attachments, including 1 video. Photos: 10 MB each. Video: 50 MB.<br />
              Media stays on this device. Text and attachment metadata are used in this LiveView session. Nothing is publicly published.
            </p>
          </div>
        </div>
      </form>
    </dialog>
    """
  end
end
