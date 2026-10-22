// Browser smoke check for the job board directory and the feed discovery card.
// Usage:
//   cd frontend && mix assets.setup && mix assets.build && mix phx.server
//   cd scripts && npm i playwright && node job_board_smoke.js
// Not part of ExUnit: LiveViewTest does not execute browser JavaScript.
// The page must be loaded through http://localhost:4000 because dev
// check_origin derives the allowed origin from the endpoint :url host.
const { chromium } = require("playwright");

(async () => {
  const executablePath = process.env.JOBLITE_CHROMIUM_PATH;
  const browser = await chromium.launch({
    ...(executablePath ? { executablePath } : {}),
    // The dev server listens on 127.0.0.1 while the endpoint url host is
    // "localhost", so the browser must resolve the name to that address.
    args: ["--host-resolver-rules=MAP localhost 127.0.0.1"],
  });
  const page = await browser.newPage();
  const consoleErrors = [];
  page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text()); });

  const base = process.env.JOBLITE_BASE_URL || "http://localhost:4000";

  const resp = await page.goto(base + "/explore", { waitUntil: "domcontentloaded", timeout: 20000 });
  if (resp.status() !== 200) throw new Error("expected 200 on /explore, got " + resp.status());
  await page.waitForSelector("[data-phx-main].phx-connected", { timeout: 15000 });
  await page.waitForSelector("#board-remote-ok", { timeout: 15000 });

  const boards = await page.$$eval(".jf-board", (nodes) => nodes.map((n) => n.id));
  if (boards.length < 9) throw new Error("expected the seeded boards, got " + boards.length);

  const mode = await page.textContent("#board-remote-ok .jf-board-mode");
  if (mode.trim() !== "Feed candidate") throw new Error("unexpected mode label: " + mode);

  const link = await page.getAttribute("#board-remotive a.jf-board-open", "href");
  if (!link || !link.startsWith("https://")) throw new Error("expected an outbound link, got " + link);

  const countries = await page.textContent("#board-jobget-countries");
  if (!countries.includes("United States")) throw new Error("no country coverage: " + countries);

  const pending = await page.textContent("#board-himalayas-categories");
  if (!pending.includes("Categories pending review")) throw new Error("unexpected categories: " + pending);

  const preferences = await page.textContent("#explore-preferences");
  if (!preferences.includes("Log in")) throw new Error("no login hint for the preferences");

  await page.fill("#explore-filters input[name='text']", "remote ok");
  await page.waitForFunction(
    () => document.querySelectorAll(".jf-board").length === 1,
    null,
    { timeout: 15000 }
  );
  const narrowed = await page.$eval(".jf-board", (n) => n.id);
  if (narrowed !== "board-remote-ok") throw new Error("filter did not narrow the list: " + narrowed);

  await page.fill("#explore-filters input[name='text']", "");
  await page.waitForFunction(
    () => document.querySelectorAll(".jf-board").length > 1,
    null,
    { timeout: 15000 }
  );

  // The directory is used on a phone: the layout must not scroll sideways.
  await page.setViewportSize({ width: 320, height: 720 });
  await page.waitForTimeout(300);
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth - document.documentElement.clientWidth
  );
  if (overflow > 1) throw new Error("horizontal overflow on /explore: " + overflow);
  await page.setViewportSize({ width: 1280, height: 900 });

  // The search field must be reachable with the keyboard and show a focus ring.
  await page.focus("#explore-filters input[name='text']");
  await page.keyboard.press("Tab");
  const focus = await page.evaluate(() => {
    const el = document.activeElement;
    if (!el) return null;
    const style = getComputedStyle(el);
    return { name: el.getAttribute("name"), outline: style.outlineStyle, width: style.outlineWidth };
  });
  if (!focus) throw new Error("nothing is focused after the keyboard move");
  if (focus.outline === "none") throw new Error("no visible focus outline");

  const saved = await page.goto(base + "/explore/saved", { waitUntil: "domcontentloaded", timeout: 20000 });
  if (!saved.url().includes("/users/log-in")) {
    throw new Error("the saved boards page must ask anonymous visitors to log in: " + saved.url());
  }

  await page.goto(base + "/", { waitUntil: "domcontentloaded", timeout: 20000 });
  await page.waitForSelector("[data-phx-main].phx-connected", { timeout: 15000 });
  await page.waitForSelector("#discovery-card", { timeout: 15000 });

  const label = await page.textContent("#discovery-card .jf-discovery-label");
  if (!label.includes("Job board directory")) throw new Error("card is not labelled: " + label);

  const cardLink = await page.getAttribute("#discovery-card a.jf-board-open", "href");
  if (!cardLink || !cardLink.startsWith("https://")) throw new Error("expected an outbound link, got " + cardLink);

  const target = await page.getAttribute("#discovery-card a.jf-board-open", "target");
  const rel = await page.getAttribute("#discovery-card a.jf-board-open", "rel");
  if (target !== "_blank" || !rel.includes("noopener")) throw new Error("unsafe outbound link");

  const facts = await page.textContent("#discovery-card .jf-discovery-facts");
  if (!facts.includes("Remote") || !facts.includes("Coverage")) {
    throw new Error("the card states no eligibility context: " + facts);
  }

  if (consoleErrors.length) throw new Error("console errors: " + consoleErrors.join(" | "));

  console.log(JSON.stringify({ ok: true, boards: boards.length, card: cardLink }));
  await browser.close();
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
