defmodule JobliteWeb.HomeLive.Components.MediaViewer do
  @moduledoc "Native full-screen dialog; the browser hook owns playback and gallery state."
  use Phoenix.Component
  import JobliteWeb.HomeLive.Components.Icons

  def media_viewer(assigns) do
    ~H"""
    <dialog
      id="feed-media-viewer"
      class="jf-dialog jf-viewer"
      phx-hook="FeedMediaViewer"
      phx-update="ignore"
      aria-label="Full-screen media viewer"
    >
      <div class="jf-viewer-layout">
        <header class="jf-dialog-header">
          <button type="button" class="jf-icon-button" data-close aria-label="Close media viewer"><.icon name="close" /></button>
          <span data-position></span><button type="button" class="jf-fit" data-fit>Fill screen</button>
        </header>
        <div class="jf-viewer-stage" data-stage></div>
        <div class="jf-viewer-controls" data-gallery-controls hidden>
          <button type="button" class="jf-icon-button" data-prev aria-label="Previous media"><.icon name="left" /></button>
          <button type="button" class="jf-icon-button" data-next aria-label="Next media"><.icon name="right" /></button>
        </div>
        <p class="jf-viewer-status" data-error role="status"></p>
        <footer class="jf-viewer-footer">
          <strong data-author></strong><p data-caption></p>
        </footer>
      </div>
    </dialog>
    """
  end
end
