import {getPreview, clearPreviews} from "./preview_files.js";

export default {
  mounted() {
    this.onClick = event => {
      const button = event.target.closest("[data-feed-action]");
      if (!button || button.disabled) return;
      const action = button.dataset.feedAction;
      if (action === "compose" || action === "reply") {
        const prefix = action === "reply" ? button.closest("[data-feed-post]")?.dataset.handle : "";
        this.el.dispatchEvent(new CustomEvent("joblite:compose", {detail: {prefix}}));
      }
      if (action === "open-media") {
        const post = button.closest("[data-feed-post]");
        const buttons = [...button.closest("[data-feed-gallery]").querySelectorAll("[data-media-id]")];
        const media = buttons.map(element => {
          const local = element.dataset.mediaLocal === "true" ? getPreview(element.dataset.mediaId) : null;
          return {kind: element.dataset.mediaKind, source: local?.url || element.dataset.mediaSource,
            thumbnail: local?.thumbnail || element.dataset.mediaThumbnail, alt: element.dataset.mediaAlt};
        });
        this.el.dispatchEvent(new CustomEvent("joblite:media", {detail: {media, index: buttons.indexOf(button), author: post.dataset.author, caption: post.dataset.body}}));
      }
    };
    this.onExit = () => clearPreviews();
    this.el.addEventListener("click", this.onClick);
    window.addEventListener("pagehide", this.onExit);
    this.hydrate();
  },
  updated() {
    this.hydrate();
  },
  hydrate() {
    this.el.querySelectorAll("[data-local-thumbnail]").forEach(image => {
      const item = getPreview(image.dataset.localThumbnail);
      const status = image.parentElement.querySelector("[data-local-state]");
      image.hidden = !item; image.parentElement.disabled = !item;
      if (item) {
        image.src = item.thumbnail; if (status) status.hidden = true; }
      else if (status) {
        status.hidden = false; status.textContent = "Preview no longer available. Choose the file again."; }
    });
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    window.removeEventListener("pagehide", this.onExit);
    clearPreviews();
  },
};
