import {stageFile, metadata, releasePreview} from "./preview_files.js";
import {renderAttachments} from "./composer_dom.js";

export default {
  mounted() {
    this.root = this.el.closest("#joblite-feed");
    this.items = [];
    this.busy = false;
    this.alive = true;
    this.connected = true;
    this.body = this.el.querySelector("[data-body]");
    this.error = this.el.querySelector("[data-error]");
    this.submit = this.el.querySelector("[data-submit]");
    this.form = this.el.querySelector("form");
    this.onOpen = event => {
      if (event.detail?.prefix && !this.body.value.trim()) this.body.value = `${event.detail.prefix} `;
      if (!this.el.open) this.el.showModal();
      this.update();
    };
    this.onClick = event => {
      const button = event.target.closest("button");
      if (!button) return;
      if (button.hasAttribute("data-close")) this.el.close();
      if (button.dataset.add) this.el.querySelector(`[data-files="${button.dataset.add}"]`).click();
      if (button.dataset.remove !== undefined && !this.busy) {
        const [item] = this.items.splice(Number(button.dataset.remove), 1);
        if (item) releasePreview(item.id);
        this.update();
      }
    };
    this.onInput = () => this.update();
    this.onChange = event => {
      if (!event.target.matches("[data-files]")) return;
      const selected = [...(event.target.files || [])];
      event.target.value = "";
      this.add(selected);
    };
    this.onSubmit = event => {
      event.preventDefault();
      if (this.busy || this.submit.disabled) return;
      this.busy = true;
      this.error.textContent = "";
      this.update();
      this.pushEvent("feed:preview-post", {body: this.body.value, media: this.items.map(metadata)}, reply => {
        if (!this.alive) return;
        this.busy = false;
        if (reply.ok) {
          this.items = []; this.body.value = ""; this.el.close(); }
        else this.error.textContent = reply.error || "The post could not be added. Try again.";
        this.update();
      });
    };
    this.root.addEventListener("joblite:compose", this.onOpen);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("change", this.onChange);
    this.body.addEventListener("input", this.onInput);
    this.form.addEventListener("submit", this.onSubmit);
  },
  async add(files) {
    if (this.busy) return;
    this.busy = true;
    this.error.textContent = "";
    this.update();
    const errors = [];
    for (const file of files) {
      if (this.items.length >= 4) {
        errors.push("Choose up to four attachments.");
        break;
      }
      if (file.type.startsWith("video/") && this.items.some(item => item.kind === "video")) {
        errors.push("Choose one video per post.");
        continue;
      }
      try {
        const item = await stageFile(file);
        if (!this.alive) {
          releasePreview(item.id);
          return;
        }
        this.items.push(item);
      } catch (error) {
        errors.push(error.message);
      }
    }
    if (!this.alive) return;
    this.busy = false;
    this.error.textContent = [...new Set(errors)].join(" ");
    this.update();
  },
  update() {
    this.submit.disabled = !this.connected || this.busy || (!this.body.value.trim() && this.items.length === 0);
    this.submit.textContent = this.busy ? "Preparing…" : "Post";
    this.el.querySelector("[data-character-count]").textContent = `${this.body.value.length} / 600`;
    this.el.querySelectorAll("[data-add]").forEach(button => {
      button.disabled = this.busy; });
    renderAttachments(this.el.querySelector("[data-attachments]"), this.items);
  },
  disconnected() {
    this.connected = false;
    this.busy = false;
    this.update();
    this.error.textContent = "Connection interrupted. Reconnect before posting.";
  },
  reconnected() {
    this.connected = true;
    this.error.textContent = "";
    this.update();
  },
  destroyed() {
    this.alive = false;
    this.items.forEach(item => releasePreview(item.id));
    this.root.removeEventListener("joblite:compose", this.onOpen);
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("change", this.onChange);
    this.body.removeEventListener("input", this.onInput);
    this.form.removeEventListener("submit", this.onSubmit);
    if (this.el.open) this.el.close();
  },
};
