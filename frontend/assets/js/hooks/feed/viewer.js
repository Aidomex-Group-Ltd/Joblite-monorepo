export default {
  mounted() {
    this.root = this.el.closest("#joblite-feed");
    this.stage = this.el.querySelector("[data-stage]");
    this.error = this.el.querySelector("[data-error]");
    this.index = 0;
    this.items = [];
    this.fit = "contain";
    this.onOpen = event => {
      this.items = event.detail.media;
      this.index = event.detail.index;
      this.fit = "contain";
      this.el.querySelector("[data-author]").textContent = event.detail.author;
      this.el.querySelector("[data-caption]").textContent = event.detail.caption;
      if (!this.el.open) this.el.showModal();
      this.render();
    };
    this.onClick = event => {
      const button = event.target.closest("button");
      if (!button) return;
      if (button.hasAttribute("data-close")) this.el.close();
      if (button.hasAttribute("data-prev")) this.move(-1);
      if (button.hasAttribute("data-next")) this.move(1);
      if (button.hasAttribute("data-fit")) {
        this.fit = this.fit === "contain" ? "cover" : "contain";
        this.applyFit();
      }
    };
    this.onClose = () => this.clear();
    this.onKey = event => {
      if (event.target.tagName === "VIDEO" || this.items.length < 2) return;
      if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
        event.preventDefault();
        this.move(event.key === "ArrowRight" ? 1 : -1);
      }
    };
    this.onDown = event => {
      this.start = event.target.tagName === "IMG" ? {x:event.clientX,y:event.clientY} : null;
    };
    this.onUp = event => {
      if (!this.start) return;
      const dx = event.clientX - this.start.x, dy = event.clientY - this.start.y;
      this.start = null;
      if (Math.abs(dx) > 65 && Math.abs(dx) > Math.abs(dy) && this.items.length > 1) this.move(dx < 0 ? 1 : -1);
      else if (dy > 100 && Math.abs(dy) > Math.abs(dx) * 1.5) this.el.close();
    };
    this.root.addEventListener("joblite:media", this.onOpen);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("close", this.onClose);
    this.el.addEventListener("keydown", this.onKey);
    this.stage.addEventListener("pointerdown", this.onDown);
    this.stage.addEventListener("pointerup", this.onUp);
  },
  render() {
    this.clear();
    this.error.textContent = "";
    const item = this.items[this.index];
    if (!item) return;
    this.el.querySelector("[data-position]").textContent = `${this.index + 1} / ${this.items.length}`;
    this.el.querySelector("[data-gallery-controls]").hidden = this.items.length < 2;
    if (!item.source) {
      this.error.textContent = "Preview no longer available. Choose the file again.";
      return;
    }
    const media = document.createElement(item.kind === "video" ? "video" : "img");
    media.src = item.source;
    if (item.kind === "video") {
      media.controls = true;
      media.playsInline = true;
      media.preload = "none";
      media.muted = true;
      media.poster = item.thumbnail || "";
      media.setAttribute("aria-label", item.alt);
    } else media.alt = item.alt;
    media.addEventListener("error", () => {
      this.error.textContent = "This media could not be loaded. Try another file or return to the feed."; });
    this.stage.append(media);
    this.applyFit();
    if (item.kind === "video") media.play().catch(() => {
      if (this.el.open) this.error.textContent = "Tap play to start the video."; });
  },
  move(delta) {
    this.index = (this.index + delta + this.items.length) % this.items.length;
    this.render();
  },
  applyFit() {
    const media = this.stage.querySelector("img,video");
    if (media) media.style.objectFit = this.fit;
    this.el.querySelector("[data-fit]").textContent = this.fit === "contain" ? "Fill screen" : "Fit media";
  },
  clear() {
    const video = this.stage.querySelector("video");
    if (video) {
      video.pause();
      video.removeAttribute("src");
      video.load();
    }
    this.stage.replaceChildren();
  },
  destroyed() {
    this.clear();
    if (this.el.open) this.el.close();
    this.root.removeEventListener("joblite:media", this.onOpen);
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("close", this.onClose);
    this.el.removeEventListener("keydown", this.onKey);
    this.stage.removeEventListener("pointerdown", this.onDown);
    this.stage.removeEventListener("pointerup", this.onUp);
  },
};
