// Browser smoke check for the connected HomeLive slice (P01.04).
// Usage:
//   cd frontend && mix assets.setup && mix assets.build && mix phx.server
//   cd scripts && npm i playwright && node browser_smoke.js
// Not part of ExUnit: LiveViewTest does not execute browser JavaScript.
// The page must be loaded through http://localhost:4000 because dev
// check_origin derives the allowed origin from the endpoint :url host.
const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const consoleErrors = [];
  const wsUrls = [];
  page.on("websocket", (ws) => wsUrls.push(ws.url()));
  page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text()); });

  const base = process.env.JOBLITE_BASE_URL || "http://localhost:4000";
  const resp = await page.goto(base + "/", { waitUntil: "domcontentloaded", timeout: 20000 });
  if (resp.status() !== 200) throw new Error("expected 200, got " + resp.status());

  await page.waitForSelector("[data-phx-main].phx-connected", { timeout: 15000 });
  const btn = page.locator("#architecture-details");
  const before = await btn.getAttribute("aria-expanded");
  await btn.click();
  await page.waitForFunction(
    () => document.querySelector("#boundary-explanation") !== null,
    null,
    { timeout: 15000 }
  );
  const after = await btn.getAttribute("aria-expanded");
  if (before !== "false" || after !== "true") throw new Error("aria-expanded not toggled");
  if (consoleErrors.length) throw new Error("console errors: " + consoleErrors.join(" | "));
  if (!wsUrls.some((u) => u.includes("/live/websocket"))) throw new Error("no LiveView websocket");

  const live = await page.evaluate(async () => (await fetch("/health/live")).status);
  const ready = await page.evaluate(async () => (await fetch("/health/ready")).status);
  if (live !== 200) throw new Error("liveness expected 200, got " + live);

  console.log(JSON.stringify({ ok: true, live, ready, websockets: wsUrls.length }));
  await browser.close();
})().catch((e) => { console.error("FAILED", e); process.exit(1); });
