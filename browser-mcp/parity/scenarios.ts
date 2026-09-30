// The 42 parity scenarios from SCENARIOS.md, as data.
//
// Shape (copied from chrome-devtools-mcp's eval harness): prompt + fixture
// route + expectations. Expectations here are outcome oracles only (answer
// regexes and fixture log events), never tool-call sequences, so any server is
// judged on whether the agent reached the outcome.
//
// `reference` drives the `browser` MCP server with no model. It returns the text
// a correct agent would answer, built from tool output. Where `browser` can only
// do a thing through `run`, the reference uses `run`.

import { inflateSync } from "node:zlib";
import type { LogEntry } from "./fixtures.ts";

export interface LogOracle {
  event: string;
  /** Exact string, or regex tested against the entry value. Omitted: any value. */
  value?: string | RegExp;
}

export interface ToolResult {
  text: string;
  isError: boolean;
  images: { data: string; mimeType: string }[];
}

export interface RefCtx {
  base: string;
  file: string;
  /** Raw MCP tools/call. */
  tool(name: string, args?: Record<string, unknown>): Promise<ToolResult>;
  /** tools/call that throws on isError and returns the text. */
  text(name: string, args?: Record<string, unknown>): Promise<string>;
  /** `open` tool; returns {url,title,status}. */
  open(path: string, engine?: "webkit" | "chromium"): Promise<{ url: string; title: string; status: number | null }>;
  /** The `run` tool. `fn` is serialised with toString(), so it must not close over anything: pass data through `arg`. */
  run<R = any>(fn: (c: { page: any; context: any; browser: any }, arg: any) => Promise<R> | R, arg?: unknown): Promise<R>;
  /** The `evaluate` tool (page context); returns the parsed JSON result. */
  evaluate<R = any>(expression: string): Promise<R>;
  /** Retry `fn` until it returns a truthy value (default 8 s). */
  poll<R>(fn: () => Promise<R | undefined | false | null>, ms?: number): Promise<R>;
  sleep(ms: number): Promise<void>;
}

export interface Scenario {
  id: string;
  group: string;
  /** With `<BASE>` and `<FILE>` placeholders. */
  prompt: string;
  /** Every regex must match the final answer. */
  answer?: RegExp[];
  /** Free-text scenarios end their prompt with a fixed `ANSWER:` line; this checks only the last such line (see `answerLine`). */
  answerLine?: { label: string; test(body: string): boolean };
  /** Every entry must be present in the fixture log. */
  log?: LogOracle[];
  /** Tool-call oracle: the agent's recorded calls must include a non-error call whose name matches the regex for its server. */
  toolCall?: { label: string; byServer: Record<string, RegExp>; /** Per server: the call must come after the last call matching this (an open-type call). */ after?: Record<string, RegExp> };
  /** The runner also records, as information only, which browser processes survive pi's exit. */
  leftover?: boolean;
  reference(c: RefCtx): Promise<string>;
}

export const render = (s: Scenario, base: string, file: string) =>
  s.prompt.replaceAll("<BASE>", base).replaceAll("<FILE>", file);

export interface OracleResult {
  kind: "answer" | "log" | "toolCall";
  name: string;
  pass: boolean;
}

export interface CalledTool {
  name: string;
  isError?: boolean;
}

const lastIndex = (calls: CalledTool[], re?: RegExp) => (re ? calls.findLastIndex((c) => re.test(c.name)) : -1);

/** Text after `ANSWER:` on the last line of `answer` that starts with it, or undefined. Free-text regexes proved brittle across three review rounds, so these scenarios pin the format and check only this line. */
export function answerLine(answer: string): string | undefined {
  const lines = answer.split(/\r?\n/).filter((l) => /^\s*ANSWER:/.test(l));
  return lines.at(-1)?.replace(/^\s*ANSWER:/, "");
}

/** Strip whitespace, backticks and quotes from one field of an ANSWER line. */
const field = (x: string) => x.replace(/[`'"]/g, "").trim();

/** `calls` and `server` are needed only for the toolCall oracle; without them it fails. Tool names are as pi reports them (`browser_close`). */
export function check(
  s: Scenario,
  answer: string,
  log: Pick<LogEntry, "event" | "value">[],
  calls: CalledTool[] = [],
  server = "",
): OracleResult[] {
  const out: OracleResult[] = [];
  for (const re of s.answer ?? []) out.push({ kind: "answer", name: String(re), pass: re.test(answer) });
  if (s.answerLine) {
    const body = answerLine(answer);
    out.push({ kind: "answer", name: `ANSWER line: ${s.answerLine.label}`, pass: body !== undefined && s.answerLine.test(body) });
  }
  for (const o of s.log ?? []) {
    const pass = log.some(
      (e) => e.event === o.event && (o.value === undefined || (typeof o.value === "string" ? e.value === o.value : o.value.test(e.value))),
    );
    out.push({ kind: "log", name: `${o.event}${o.value === undefined ? "" : " " + o.value}`, pass });
  }
  if (s.toolCall) {
    const re = s.toolCall.byServer[server];
    out.push({
      kind: "toolCall",
      name: `${s.toolCall.label} [${server || "?"}]: ${re ?? "no pattern"}`,
      pass: !!re && calls.some((c, i) => !c.isError && re.test(c.name) && i > lastIndex(calls, s.toolCall!.after?.[server])),
    });
  }
  return out;
}

// ---------------------------------------------------------------- helpers

/** Minimal PNG decoder (8-bit RGB or RGBA, non-interlaced) so the screenshot reference needs no dependency. */
function decodePng(buf: Buffer) {
  let o = 8, w = 0, h = 0, ct = 0;
  const idat: Buffer[] = [];
  while (o < buf.length) {
    const len = buf.readUInt32BE(o);
    const type = buf.toString("ascii", o + 4, o + 8);
    const d = buf.subarray(o + 8, o + 8 + len);
    if (type === "IHDR") {
      w = d.readUInt32BE(0);
      h = d.readUInt32BE(4);
      ct = d[9]!;
      if (d[8] !== 8 || d[12] !== 0) throw new Error("unsupported PNG (need 8-bit, non-interlaced)");
    } else if (type === "IDAT") idat.push(d);
    else if (type === "IEND") break;
    o += 12 + len;
  }
  const bpp = ct === 6 ? 4 : ct === 2 ? 3 : 0;
  if (!bpp) throw new Error(`unsupported PNG color type ${ct}`);
  const raw = inflateSync(Buffer.concat(idat));
  const stride = w * bpp;
  const px = Buffer.alloc(h * stride);
  for (let y = 0; y < h; y++) {
    const ft = raw[y * (stride + 1)]!;
    for (let x = 0; x < stride; x++) {
      const a = x >= bpp ? px[y * stride + x - bpp]! : 0;
      const b = y > 0 ? px[(y - 1) * stride + x]! : 0;
      const c = x >= bpp && y > 0 ? px[(y - 1) * stride + x - bpp]! : 0;
      const v = raw[y * (stride + 1) + 1 + x]!;
      let r: number;
      if (ft === 0) r = v;
      else if (ft === 1) r = v + a;
      else if (ft === 2) r = v + b;
      else if (ft === 3) r = v + ((a + b) >> 1);
      else {
        const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        r = v + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c);
      }
      px[y * stride + x] = r & 255;
    }
  }
  return { w, h, bpp, px };
}

const PALETTE: Record<string, [number, number, number]> = {
  red: [255, 0, 0], green: [0, 160, 0], blue: [0, 0, 255], yellow: [255, 255, 0], orange: [255, 165, 0],
  purple: [128, 0, 128], black: [0, 0, 0], gray: [128, 128, 128], white: [255, 255, 255],
};
const colorName = (r: number, g: number, b: number) =>
  Object.entries(PALETTE).sort(
    (x, y) => (x[1][0] - r) ** 2 + (x[1][1] - g) ** 2 + (x[1][2] - b) ** 2 - ((y[1][0] - r) ** 2 + (y[1][1] - g) ** 2 + (y[1][2] - b) ** 2),
  )[0]![0];

const stripLoc = (l: string) => l.replace(/ \([^()\s]*:\d+:\d+\)$/, "");

// ---------------------------------------------------------------- scenarios

export const scenarios: Scenario[] = [
  // --- Navigation and pages
  {
    id: "nav-title",
    group: "navigation",
    prompt: "Open <BASE>/title and tell me the exact page title.",
    answer: [/Parity Fixture 7Q/i],
    async reference(c) {
      const r = await c.open("/title");
      return `The page title is "${r.title}".`;
    },
  },
  {
    id: "back-forward",
    group: "navigation",
    prompt: "Open <BASE>/a, follow the link to page B, then go back and tell me the main heading of the page you end up on.",
    answer: [/Page A heading/i],
    log: [{ event: "visit", value: "b" }],
    async reference(c) {
      await c.open("/a");
      const h = await c.run(async ({ page }) => {
        await page.getByRole("link", { name: /page b/i }).click();
        await page.waitForURL(/\/b$/);
        await page.goBack();
        return await page.locator("h1").innerText();
      });
      return `After going back, the main heading is "${h}".`;
    },
  },
  {
    id: "reload",
    group: "navigation",
    prompt: "Open <BASE>/counter, reload it twice, and tell me the number it shows at the end.",
    answer: [/\b3\b/],
    log: [{ event: "counter", value: "3" }],
    async reference(c) {
      await c.open("/counter");
      const n = await c.run(async ({ page }) => {
        await page.reload();
        await page.reload();
        return await page.locator("#n").innerText();
      });
      return `The page shows ${n}.`;
    },
  },
  {
    id: "new-tab",
    group: "navigation",
    prompt: "Open <BASE>/links, open the Docs link, which opens in a new tab, and tell me the titles of both tabs.",
    answer: [/Links 50/, /Docs 51/],
    async reference(c) {
      await c.open("/links");
      const titles = await c.run<string[]>(async ({ page, context }) => {
        const [p2] = await Promise.all([context.waitForEvent("page"), page.getByRole("link", { name: "Docs" }).click()]);
        await p2.waitForLoadState();
        return await Promise.all(context.pages().map((p: any) => p.title()));
      });
      return `The two tabs are titled: ${titles.map((t) => `"${t}"`).join(" and ")}.`;
    },
  },
  {
    id: "tabs-close",
    group: "navigation",
    prompt: "Open <BASE>/a and <BASE>/b in two separate tabs, close the tab with page A, and tell me the title of the tab that is still open.",
    answer: [/Page B/i],
    log: [{ event: "visit", value: "a" }, { event: "visit", value: "b" }],
    async reference(c) {
      await c.open("/a");
      const left = await c.run<string[]>(
        async ({ context }, base) => {
          const p2 = await context.newPage();
          await p2.goto(base + "/b");
          for (const p of context.pages()) if ((await p.title()) === "Page A") await p.close();
          return await Promise.all(context.pages().map((p: any) => p.title()));
        },
        c.base,
      );
      return `The tab still open is titled "${left.join(", ")}".`;
    },
  },
  {
    id: "wait-text",
    group: "navigation",
    prompt: "Open <BASE>/delayed and tell me the code that appears on the page once it finishes loading.",
    answer: [/READY-83/],
    async reference(c) {
      await c.open("/delayed");
      const t = await c.run(async ({ page }) => {
        const el = page.getByText(/READY-\d+/);
        await el.waitFor({ timeout: 10000 });
        return await el.innerText();
      });
      return `The code is ${t}.`;
    },
  },

  // --- Reading content
  {
    id: "a11y-label",
    group: "reading",
    prompt: "Open <BASE>/a11y. What is the accessible name of the icon-only button?",
    answer: [/Submit order 19/i],
    async reference(c) {
      await c.open("/a11y");
      const snap = await c.text("snapshot");
      const name = /button "([^"]+)"/.exec(snap)?.[1];
      if (!name) throw new Error(`no named button in snapshot:\n${snap}`);
      return `The accessible name is "${name}".`;
    },
  },
  {
    id: "table-sum",
    group: "reading",
    prompt: "Open <BASE>/table and give me the total of the Amount column.",
    answer: [/1,?234/],
    async reference(c) {
      await c.open("/table");
      const sum = await c.evaluate<number>(
        `(() => { const i = [...document.querySelectorAll('th')].findIndex(x => x.textContent.trim() === 'Amount'); return [...document.querySelectorAll('tbody tr')].reduce((a, r) => a + Number(r.children[i].textContent.replace(/[^0-9.]/g, '')), 0); })()`,
      );
      return `The Amount column totals ${sum}.`;
    },
  },
  {
    id: "iframe-text",
    group: "reading",
    prompt: "Open <BASE>/frame. What secret code is shown inside the embedded frame?",
    answer: [/FRAME-SECRET-5/],
    async reference(c) {
      await c.open("/frame");
      const t = await c.run(async ({ page }) => {
        const f = page.frames().find((x: any) => x.url().endsWith("/frame-inner"));
        if (!f) throw new Error("frame not found");
        return await f.locator("#secret").innerText();
      });
      return `The embedded frame shows ${t}.`;
    },
  },
  {
    id: "shadow-text",
    group: "reading",
    prompt: "Open <BASE>/shadow. What code is rendered inside the custom element?",
    answer: [/SHADOW-42/],
    async reference(c) {
      await c.open("/shadow");
      const t = await c.evaluate<string>(`document.querySelector('x-card').shadowRoot.textContent`);
      return `The custom element renders ${t}.`;
    },
  },

  // --- Input
  {
    id: "form-submit",
    group: "input",
    prompt: "Open <BASE>/form, fill in the name Ada Lovelace and the email ada@example.com, and submit the form.",
    log: [
      { event: "submit", value: /(^|&)name=Ada Lovelace(&|$)/ },
      { event: "submit", value: /(^|&)email=ada@example\.com(&|$)/ },
    ],
    async reference(c) {
      await c.open("/form");
      await c.run(async ({ page }) => {
        await page.getByLabel("Name").fill("Ada Lovelace");
        await page.getByLabel("Email").fill("ada@example.com");
        await Promise.all([page.waitForLoadState("load"), page.getByRole("button", { name: "Submit" }).click()]);
      });
      return "Submitted the form.";
    },
  },
  {
    id: "form-controls",
    group: "input",
    prompt: "Open <BASE>/controls, choose Green, tick Subscribe, pick Large, and submit.",
    log: [
      { event: "controls", value: /(^|&)color=green(&|$)/ },
      { event: "controls", value: /(^|&)subscribe=on(&|$)/ },
      { event: "controls", value: /(^|&)size=large(&|$)/ },
    ],
    async reference(c) {
      await c.open("/controls");
      await c.run(async ({ page }) => {
        await page.getByLabel("Color").selectOption({ label: "Green" });
        await page.getByLabel("Subscribe").check();
        await page.getByLabel("Large").check();
        await Promise.all([page.waitForLoadState("load"), page.getByRole("button", { name: "Submit" }).click()]);
      });
      return "Submitted the form.";
    },
  },
  {
    id: "hover",
    group: "input",
    prompt: "Open <BASE>/hover. Hover over the help icon and tell me what the tooltip says.",
    answer: [/TIP-77/],
    log: [{ event: "hovered" }],
    async reference(c) {
      await c.open("/hover");
      const t = await c.run(async ({ page }) => {
        await page.locator("#help").hover();
        await page.waitForFunction(() => document.querySelector("#tip")!.textContent !== "");
        return await page.locator("#tip").innerText();
      });
      return `The tooltip says ${t}.`;
    },
  },
  {
    id: "drag-drop",
    group: "input",
    prompt: "Open <BASE>/drag and drag the card into the drop zone.",
    log: [{ event: "dropped" }],
    async reference(c) {
      await c.open("/drag");
      const t = await c.run(async ({ page }) => {
        await page.locator("#card").dragTo(page.locator("#zone"));
        await page.waitForFunction(() => document.querySelector("#zone")!.textContent === "Dropped!");
        return await page.locator("#zone").innerText();
      });
      return `The drop zone now reads "${t}".`;
    },
  },
  {
    id: "key-press",
    group: "input",
    prompt: "Open <BASE>/keys and close the modal with the keyboard, not the mouse.",
    log: [{ event: "escape" }],
    async reference(c) {
      await c.open("/keys");
      const gone = await c.run(async ({ page }) => {
        await page.keyboard.press("Escape");
        await page.waitForFunction(() => !document.querySelector("#modal"));
        return await page.locator("#status").innerText();
      });
      return `Pressed Escape; the page reports ${gone}.`;
    },
  },
  {
    id: "file-upload",
    group: "input",
    prompt: "Open <BASE>/upload and upload the file at <FILE>.",
    log: [{ event: "upload", value: /UPLOAD-PAYLOAD-9/ }],
    async reference(c) {
      await c.open("/upload");
      await c.run(
        async ({ page }, file) => {
          await page.locator("input[type=file]").setInputFiles(file);
          await Promise.all([page.waitForLoadState("load"), page.getByRole("button", { name: "Upload" }).click()]);
        },
        c.file,
      );
      return "Uploaded the file.";
    },
  },
  {
    id: "confirm-dialog",
    group: "input",
    prompt: "Open <BASE>/dialog, click Delete, and accept the confirmation. Tell me what the confirmation asked.",
    answer: [/Delete item 12/i],
    log: [{ event: "confirm", value: "true" }],
    async reference(c) {
      await c.open("/dialog");
      const msg = await c.run<string>(async ({ page }) => {
        let m = "";
        page.once("dialog", (d: any) => {
          m = d.message();
          d.accept();
        });
        await page.getByRole("button", { name: "Delete" }).click();
        await page.waitForFunction(() => document.querySelector("#out")!.textContent !== "");
        return m;
      });
      return `The confirmation asked: "${msg}"`;
    },
  },
  {
    id: "prompt-dialog",
    group: "input",
    prompt: "Open <BASE>/prompt, click Enter code, and answer the prompt with PX-31.",
    log: [{ event: "prompt", value: "PX-31" }],
    async reference(c) {
      await c.open("/prompt");
      const out = await c.run(async ({ page }) => {
        page.once("dialog", (d: any) => d.accept("PX-31"));
        await page.getByRole("button", { name: "Enter code" }).click();
        await page.waitForFunction(() => document.querySelector("#out")!.textContent !== "");
        return await page.locator("#out").innerText();
      });
      return `Answered the prompt; the page shows "${out}".`;
    },
  },
  {
    id: "double-click",
    group: "input",
    prompt: "Open <BASE>/dbl and double-click the box.",
    log: [{ event: "dblclick" }],
    async reference(c) {
      await c.open("/dbl");
      await c.run(async ({ page }) => {
        await page.locator("#box").dblclick();
        await new Promise((r) => setTimeout(r, 300));
      });
      return "Double-clicked the box.";
    },
  },
  {
    id: "infinite-scroll",
    group: "input",
    prompt: "Open <BASE>/scroll and tell me what item 47 says. Items load as you scroll.",
    answer: [/KIWI/],
    async reference(c) {
      await c.open("/scroll");
      const t = await c.run<string>(async ({ page }) => {
        for (let i = 0; i < 40; i++) {
          if ((await page.locator(".row").count()) >= 47) break;
          await page.mouse.wheel(0, 3000);
          await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
          await new Promise((r) => setTimeout(r, 150));
        }
        return await page.locator(".row").nth(46).innerText();
      });
      return `Item 47 says "${t}".`;
    },
  },

  // --- Console and network
  {
    id: "console-errors",
    group: "console-network",
    prompt:
      "Open <BASE>/console. List every console error message and tell me how many warnings there were. End your answer with a final line exactly in the form `ANSWER: <error messages separated by commas> | <number of warnings>`.",
    answerLine: {
      label: "errors PARITY_ERR_1 and PARITY_ERR_2 | 2 warnings",
      test(body) {
        const i = body.lastIndexOf("|");
        if (i < 0) return false;
        const left = body.slice(0, i);
        const count = field(body.slice(i + 1)).replace(/\.$/, "");
        return /PARITY_ERR_1/.test(left) && /PARITY_ERR_2/.test(left) && /^(?:2|two)$/i.test(count);
      },
    },
    async reference(c) {
      await c.open("/console");
      const lines = (await c.text("console")).split("\n");
      const errors = lines.filter((l) => l.startsWith("[error]")).map((l) => stripLoc(l.slice(8)));
      const warnings = lines.filter((l) => l.startsWith("[warning]")).length;
      return `Console errors: ${errors.join("; ")}. There were ${warnings} warnings.\nANSWER: ${errors.join(", ")} | ${warnings}`;
    },
  },
  {
    id: "uncaught-exception",
    group: "console-network",
    prompt: "Open <BASE>/exception. The page throws an uncaught error. What is the error message and which function threw it?",
    answer: [/KABOOM-6/, /explodeHere/],
    async reference(c) {
      await c.open("/exception");
      const err = await c.poll(async () => {
        const t = await c.text("console");
        const i = t.indexOf("[pageerror]");
        return i >= 0 ? t.slice(i + "[pageerror]".length).trim() : undefined;
      });
      const lines = err.split("\n").map((l) => l.trim());
      const msg = lines[0]!.replace(/^\w*Error:\s*/, "");
      const fn = lines.slice(1).map((l) => /^(?:at\s+)?([\w$.<>]+)[@\s(]/.exec(l)?.[1]).find(Boolean);
      return `The error message is "${msg}", thrown from the function ${fn}.`;
    },
  },
  {
    id: "failed-request",
    group: "console-network",
    prompt:
      "Open <BASE>/requests. Which requests failed, and with which status codes? End your answer with a final line exactly in the form `ANSWER: <path> <status>, <path> <status>` listing only the failed requests.",
    answerLine: {
      label: "exactly /api/broken 500 and /api/missing 404, no /api/ok",
      test(body) {
        const pairs = [...body.replace(/[`'"]/g, "").replace(/\bHTTP\b/gi, "").matchAll(/(\/api\/[\w-]+)[\s:=(]*(\d{3})/g)].map((m) => `${m[1]} ${m[2]}`);
        return pairs.length === 2 && pairs.includes("/api/broken 500") && pairs.includes("/api/missing 404") && !/\/api\/ok\b/.test(body);
      },
    },
    async reference(c) {
      await c.open("/requests");
      const rows = await c.poll(async () => {
        const r: any[] = JSON.parse(await c.text("network", { filter: "/api/" }));
        return r.length >= 3 ? r : undefined;
      });
      const failed = rows.filter((r) => r.failure || r.status >= 400);
      const pairs = failed.map((r) => `${new URL(r.url).pathname} ${r.status ?? r.failure}`);
      return `Failed requests: ${pairs.join("; ")}.\nANSWER: ${pairs.join(", ")}`;
    },
  },
  {
    id: "response-body",
    group: "console-network",
    prompt: "Open <BASE>/token. The page fetches a token from the API but does not show it. What is the token?",
    answer: [/token-XYZ-88/],
    async reference(c) {
      await c.open("/token");
      const idx = await c.poll(async () => {
        const r: any[] = JSON.parse(await c.text("network", { filter: "/api/token" }));
        return r[0]?.index as number | undefined;
      });
      const d = JSON.parse(await c.text("network", { index: idx }));
      return `The token is ${JSON.parse(d.body).token}.`;
    },
  },
  {
    id: "request-header",
    group: "console-network",
    prompt: "Open <BASE>/header. What custom x- header does the page send with its API request, and what is its value?",
    answer: [/x-parity/i, /\b99\b/],
    async reference(c) {
      await c.open("/header");
      const idx = await c.poll(async () => {
        const r: any[] = JSON.parse(await c.text("network", { filter: "/api/echo" }));
        return r[0]?.index as number | undefined;
      });
      const d = JSON.parse(await c.text("network", { index: idx }));
      const xs = Object.entries(d.requestHeaders as Record<string, string>).filter(([k]) => k.startsWith("x-"));
      return `The page sends ${xs.map(([k, v]) => `${k}: ${v}`).join(", ")}.`;
    },
  },
  {
    id: "post-body",
    group: "console-network",
    prompt: "Open <BASE>/save. What JSON body does the page send to the save endpoint?",
    answer: [/DRAFT-204/],
    async reference(c) {
      await c.open("/save");
      const idx = await c.poll(async () => {
        const r: any[] = JSON.parse(await c.text("network", { filter: "/api/save" }));
        return r[0]?.index as number | undefined;
      });
      const d = JSON.parse(await c.text("network", { index: idx }));
      return `The page sends ${d.postData}.`;
    },
  },

  // --- Scripts, DOM, CSS
  {
    id: "query-count",
    group: "dom-css",
    prompt: "Open <BASE>/items. How many elements have the class item, including hidden ones?",
    answer: [/\b17\b/],
    async reference(c) {
      await c.open("/items");
      const n = await c.evaluate<number>(`document.querySelectorAll('.item').length`);
      return `There are ${n} elements with the class item.`;
    },
  },
  {
    id: "computed-style",
    group: "dom-css",
    prompt: "Open <BASE>/style. What is the computed text color of the warning element?",
    answer: [/214,\s*40,\s*40|#d62828/i],
    async reference(c) {
      await c.open("/style");
      const d = JSON.parse(await c.text("dom", { selector: "#warn", styles: ["color"] }));
      return `The computed color is ${d.elements[0].styles.color}.`;
    },
  },
  {
    id: "event-listener",
    group: "dom-css",
    prompt:
      "Open <BASE>/listeners. Which of the three buttons actually has a click handler, and what does the handler do? End your answer with a final line exactly in the form `ANSWER: <button id> | <what the handler logs>`.",
    answerLine: {
      label: "go | GO-CLICKED (id case-insensitive, logged text case-sensitive)",
      test(body) {
        const parts = body.split("|");
        if (parts.length !== 2) return false;
        return field(parts[0]!).replace(/^#/, "").toLowerCase() === "go" && field(parts[1]!) === "GO-CLICKED";
      },
    },
    async reference(c) {
      await c.open("/listeners", "chromium");
      const d = JSON.parse(await c.text("dom", { selector: "button", limit: 10 }));
      const hit = d.elements.find((e: any) => (e.listeners ?? []).some((l: any) => l.type === "click"));
      if (!hit) throw new Error("no element with a click listener");
      // The logged text is built at runtime, so click the button and read what reached the console.
      await c.run(async ({ page }, id) => await page.click("#" + id), hit.attributes.id);
      const logged = await c.poll(async () => {
        const l = (await c.text("console")).split("\n").find((x) => x.startsWith("[log]"));
        return l ? stripLoc(l.slice(6)) : undefined;
      });
      return `Only the button #${hit.attributes.id} has a click handler; it logs ${logged} to the console.\nANSWER: ${hit.attributes.id} | ${logged}`;
    },
  },
  {
    id: "css-cascade",
    group: "dom-css",
    prompt: "Open <BASE>/cascade. The card is stuck at 400px wide even though a rule sets max-width 900px. Why is that rule not winning?",
    answer: [/layer/i, /400/],
    async reference(c) {
      await c.open("/cascade");
      const r = await c.evaluate<{ layer: string | null; winner: string; maxWidth: string }>(`(() => {
        const out = { layer: null, winner: null, maxWidth: getComputedStyle(document.querySelector('.card')).maxWidth };
        for (const sheet of document.styleSheets) for (const rule of sheet.cssRules) {
          if (rule instanceof CSSLayerBlockRule) { for (const r of rule.cssRules) if (r.style && r.style.maxWidth === '900px') out.layer = rule.name; }
          else if (rule.style && rule.style.maxWidth) out.winner = rule.selectorText + ' { max-width: ' + rule.style.maxWidth + ' }';
        }
        return out;
      })()`);
      if (!r.layer) throw new Error("layered rule not found");
      return `The 900px rule sits inside @layer ${r.layer}, and cascade layers lose to unlayered styles: the unlayered rule ${r.winner} wins, so the computed max-width is ${r.maxWidth}.`;
    },
  },
  {
    id: "local-storage",
    group: "dom-css",
    prompt: "Open <BASE>/storage. What value does the page store in localStorage under the key parity, and what is the name and value of the HttpOnly cookie it sets?",
    answer: [/LS-63/, /SESS-17/],
    async reference(c) {
      await c.open("/storage");
      const ls = await c.evaluate<string>(`localStorage.getItem('parity')`);
      const cookies = await c.run<{ name: string; value: string; httpOnly: boolean }[]>(async ({ context }) => await context.cookies());
      const http = cookies.filter((k) => k.httpOnly);
      return `localStorage parity is ${ls}. HttpOnly cookie: ${http.map((k) => `${k.name}=${k.value}`).join(", ")}.`;
    },
  },

  // --- Emulation
  {
    id: "viewport",
    group: "emulation",
    prompt: "Open <BASE>/responsive at a 375 pixel wide viewport and tell me which layout code it shows.",
    answer: [/MOBILE-LAYOUT/],
    log: [{ event: "viewport", value: "375" }],
    async reference(c) {
      await c.open("/responsive");
      const t = await c.run(async ({ page }) => {
        await page.setViewportSize({ width: 375, height: 700 });
        await page.waitForFunction(() => document.querySelector("#layout")!.textContent === "MOBILE-LAYOUT");
        return await page.locator("#layout").innerText();
      });
      return `At 375px the page shows ${t}.`;
    },
  },
  {
    id: "dark-mode",
    group: "emulation",
    prompt: "Open <BASE>/scheme with the dark color scheme preferred and tell me the code it shows.",
    answer: [/DARK-ON/],
    log: [{ event: "scheme", value: "dark" }],
    async reference(c) {
      await c.open("/scheme");
      const t = await c.run(async ({ page }) => {
        await page.emulateMedia({ colorScheme: "dark" });
        await page.waitForFunction(() => document.querySelector("#out")!.textContent === "DARK-ON");
        return await page.locator("#out").innerText();
      });
      return `With dark preferred the page shows ${t}.`;
    },
  },
  {
    id: "offline",
    group: "emulation",
    prompt: "Open <BASE>/offline, then simulate losing the network connection, and tell me what the page shows.",
    answer: [/OFFLINE-BANNER/],
    async reference(c) {
      await c.open("/offline");
      const t = await c.run(async ({ page, context }) => {
        await context.setOffline(true);
        const b = page.locator("#banner");
        await page.waitForFunction(() => document.querySelector("#banner")!.textContent !== "", null, { timeout: 8000 });
        return await b.innerText();
      });
      return `Offline, the page shows ${t}.`;
    },
  },
  {
    id: "geolocation",
    group: "emulation",
    prompt: "Open <BASE>/geo with the location set to latitude 40.7128, longitude -74.006, and tell me what the page prints.",
    answer: [/40\.71/],
    log: [{ event: "geo", value: /40\.7128/ }],
    async reference(c) {
      await c.open("/geo");
      const t = await c.run(async ({ page, context }) => {
        await context.grantPermissions(["geolocation"]);
        await context.setGeolocation({ latitude: 40.7128, longitude: -74.006 });
        await page.reload();
        await page.waitForFunction(() => document.querySelector("#out")!.textContent !== "waiting", null, { timeout: 10000 });
        return await page.locator("#out").innerText();
      });
      return `The page prints ${t}.`;
    },
  },
  {
    id: "user-agent",
    group: "emulation",
    prompt: "Open <BASE>/ua with the user agent set to ParityBot/1.0 and tell me the code it shows.",
    answer: [/UA-PARITY-OK/],
    log: [{ event: "ua", value: /ParityBot\/1\.0/ }],
    async reference(c) {
      await c.open("/title");
      const t = await c.run(
        async ({ browser }, base) => {
          const ctx = await browser.newContext({ userAgent: "ParityBot/1.0" });
          try {
            const p = await ctx.newPage();
            await p.goto(base + "/ua");
            return await p.locator("#out").innerText();
          } finally {
            await ctx.close();
          }
        },
        c.base,
      );
      return `With that user agent the page shows ${t}.`;
    },
  },
  {
    id: "print-media",
    group: "emulation",
    prompt: "Open <BASE>/print. What text becomes visible when the page is rendered for print?",
    answer: [/PRINT-ONLY-8/],
    log: [{ event: "print", value: "1" }],
    async reference(c) {
      await c.open("/print");
      const t = await c.run(async ({ page }) => {
        await page.emulateMedia({ media: "print" });
        const visible = await page.locator(".p").isVisible();
        return visible ? await page.locator(".p").innerText() : "(nothing)";
      });
      return `In print media the page shows ${t}.`;
    },
  },

  // --- Performance, memory, visuals
  {
    id: "slow-resource",
    group: "perf-visual",
    prompt: "Open <BASE>/perf. Which resource slows the page load the most, and roughly how long does it take?",
    answer: [/\br4\.js\b/],
    async reference(c) {
      await c.open("/perf");
      const rs = await c.evaluate<{ name: string; ms: number }[]>(
        `performance.getEntriesByType('resource').map(e => ({ name: e.name, ms: Math.round(e.duration) }))`,
      );
      const top = rs.sort((a, b) => b.ms - a.ms)[0]!;
      return `The slowest resource is ${new URL(top.name).pathname.slice(1)}, taking about ${top.ms} ms.`;
    },
  },
  {
    id: "lcp-element",
    group: "perf-visual",
    prompt: "Open <BASE>/lcp. What is the Largest Contentful Paint element?",
    // The image is the answer; claiming the paragraph (#t3) fails.
    answer: [/^(?![\s\S]*\bt3\b)[\s\S]*\b(i7|p9\.png)\b/],
    async reference(c) {
      await c.open("/lcp", "chromium");
      const r = await c.evaluate<string>(
        `new Promise((res) => { let last; new PerformanceObserver((l) => { last = l.getEntries().at(-1); }).observe({ type: 'largest-contentful-paint', buffered: true }); setTimeout(() => res(last && last.element ? last.element.tagName.toLowerCase() + (last.element.id ? '#' + last.element.id : '') : 'none'), 1000); })`,
      );
      return `The LCP element is ${r}.`;
    },
  },
  {
    id: "memory-leak",
    group: "perf-visual",
    prompt: "Open <BASE>/leak. Clicking the button leaks memory. Click it five times and tell me which object type is growing.",
    answer: [/LeakyThing/],
    async reference(c) {
      await c.open("/leak", "chromium");
      await c.text("heap_snapshot");
      await c.run(async ({ page }) => {
        for (let i = 0; i < 5; i++) await page.click("#leak");
      });
      const after = JSON.parse(await c.text("heap_snapshot")) as { userClasses: { name: string; countDelta: number }[] };
      const grown = after.userClasses.slice(0, 3);
      return `Growing object types between the snapshots: ${grown.map((g) => `${g.name} (+${g.countDelta})`).join(", ")}.`;
    },
  },
  {
    id: "screenshot-color",
    group: "perf-visual",
    prompt: "Open <BASE>/visual. What color is the large square drawn on the canvas?",
    answer: [/\bred\b/i],
    async reference(c) {
      await c.open("/visual");
      const shot = await c.tool("screenshot");
      const img = shot.images[0];
      if (!img) throw new Error("screenshot returned no image");
      const { px, bpp } = decodePng(Buffer.from(img.data, "base64"));
      const counts = new Map<number, number>();
      for (let i = 0; i < px.length; i += bpp) {
        const r = px[i]!, g = px[i + 1]!, b = px[i + 2]!;
        if (r > 240 && g > 240 && b > 240) continue;
        const k = (r << 16) | (g << 8) | b;
        counts.set(k, (counts.get(k) ?? 0) + 1);
      }
      const [key] = [...counts.entries()].sort((x, y) => y[1] - x[1])[0] ?? [];
      if (key === undefined) throw new Error("screenshot is blank");
      return `The large square is ${colorName((key >> 16) & 255, (key >> 8) & 255, key & 255)}.`;
    },
  },
  {
    id: "cleanup",
    group: "perf-visual",
    prompt: "Open <BASE>/a, read its heading, and make sure no browser, page, or tab is left open when you are done.",
    answer: [/Page A heading/i],
    leftover: true,
    toolCall: {
      label: "closes the browser or its last page",
      byServer: {
        browser: /^browser_close$/,
        // chrome-devtools-mcp has no browser-close tool, and `close_page` refuses to close the last page, so nothing can match.
        "chrome-devtools": /^chrome-devtools_close_browser$/,
        safari: /^safari_close_tab$/,
      },
      after: {
        browser: /^browser_open$/,
        "chrome-devtools": /^chrome-devtools_(navigate_page|new_page)$/,
        safari: /^safari_(navigate_to_url|create_tab)$/,
      },
    },
    async reference(c) {
      await c.open("/a");
      const h = await c.evaluate<string>(`document.querySelector('h1').textContent`);
      await c.text("close");
      return `The heading is "${h}". The browser is closed.`;
    },
  },
];
