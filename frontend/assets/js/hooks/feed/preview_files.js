// Local-only media ownership. Never send File objects, blob URLs, or data URLs to LiveView.
const files = new Map();
const types = new Map([
  ["image/jpeg", "image"], ["image/png", "image"], ["image/webp", "image"],
  ["video/mp4", "video"], ["video/webm", "video"],
]);
export const getPreview = id => files.get(id);
export function releasePreview(id) {
  const media = files.get(id);
  if (media) URL.revokeObjectURL(media.url);
  files.delete(id);
}
export function clearPreviews() {
  [...files.keys()].forEach(releasePreview);
}
export function metadata(media) {
  return {id: media.id, kind: media.kind, type: media.type, name: media.name};
}
export async function stageFile(file) {
  const kind = types.get(file.type);
  if (!kind) throw Error("Choose JPG, PNG, WebP, MP4, or WebM.");
  const limit = kind === "video" ? 50 : 10;
  if (!file.size || file.size > limit * 1024 * 1024) throw Error(`Choose a non-empty ${kind} no larger than ${limit} MB.`);
  const uuid = globalThis.crypto?.randomUUID?.() || `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const entry = {id: `local-${uuid}`, kind, type: file.type, name: file.name.slice(0, 100), url: URL.createObjectURL(file)};
  try {
    entry.thumbnail = await thumbnail(entry);
    files.set(entry.id, entry);
    return entry;
  } catch (error) {
    URL.revokeObjectURL(entry.url);
    throw error;
  }
}
async function thumbnail(entry) {
  const element = document.createElement(entry.kind === "video" ? "video" : "img");
  let timeout;
  const ready = new Promise((resolve, reject) => {
    timeout = setTimeout(() => reject(Error("This file could not be decoded. Try a different file.")), 8000);
    element.addEventListener(entry.kind === "video" ? "loadeddata" : "load", resolve, {once: true});
    element.addEventListener("error", () => reject(Error("This file could not be decoded. Try a different file.")), {once: true});
  });
  if (entry.kind === "video") {
    element.muted = true;
    element.playsInline = true;
    element.preload = "auto";
  }
  element.src = entry.url;
  try {
    await ready;
    const width = element.videoWidth || element.naturalWidth;
    const height = element.videoHeight || element.naturalHeight;
    if (!width || !height) throw Error("This media has no readable dimensions.");
    const scale = Math.min(1, 600 / Math.max(width, height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(1, Math.round(width * scale));
    canvas.height = Math.max(1, Math.round(height * scale));
    canvas.getContext("2d").drawImage(element, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL("image/jpeg", 0.78);
  } finally {
    clearTimeout(timeout);
    if (entry.kind === "video") {
      element.pause();
      element.removeAttribute("src");
      element.load();
    }
  }
}
