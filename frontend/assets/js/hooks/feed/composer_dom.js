export function renderAttachments(container, items) {
  container.replaceChildren();
  items.forEach((item, index) => {
    const tile = document.createElement("div");
    tile.className = "jf-attach";
    const image = document.createElement("img");
    image.src = item.thumbnail;
    image.alt = item.name;
    const kind = document.createElement("span");
    kind.className = "jf-file-kind";
    kind.textContent = item.kind === "video" ? "Video" : "Photo";
    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "jf-attach-remove";
    remove.dataset.remove = String(index);
    remove.setAttribute("aria-label", `Remove ${item.name}`);
    remove.textContent = "×";
    tile.append(image, kind, remove);
    container.append(tile);
  });
}
