#!/usr/bin/env bun
// Browser MCP server.
//
// Why: the chrome-devtools and Safari MCP servers drive the user's own
// browser windows and steal focus. This server drives Playwright's bundled
// WebKit or Chromium, headless by default, so agent browser work never
// touches the desktop. One browser, one context, one page at a time.
//
// Tools: open, close, snapshot, screenshot, console, network (list or one
// request in full), evaluate (JS in the page), dom (elements, computed styles,
// event listeners), performance (web vitals, CDP metrics), trace and
// heap_snapshot (chromium only, write files), and `run`, an escape hatch that
// hands Playwright objects to arbitrary server-side code. The browser closes
// on `close`, after BROWSER_MCP_IDLE_MS of inactivity (default 10 min), and on
// exit. Files go to BROWSER_MCP_OUT (default $TMPDIR/browser-mcp).

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { chromium, webkit, type Browser, type BrowserContext, type Page, type Request } from "playwright";
import { z } from "zod";

// stdout is the MCP JSON-RPC channel: anything `run` code or a listener logs goes to stderr.
console.log = console.info = console.debug = console.error;

const CAP = 1000;

interface Session {
  engine: "webkit" | "chromium";
  headed: boolean;
  viewport?: { width: number; height: number };
  colorScheme?: "light" | "dark" | "no-preference";
  media?: "screen" | "print";
  consoleDropped: number;
  networkDropped: number;
  browser: Browser;
  context: BrowserContext;
  page: Page;
  console: string[];
  network: { sum: Record<string, unknown>; req: Request }[];
  tracing: boolean;
  heap?: Map<string, [number, number]>;
}

let s: Session | undefined;

let launching: { key: string; p: Promise<Session> } | undefined;

// Notes produced outside a tool call (idle close, disconnect) wait here for the next tool result, and go to stderr.
const pending: string[] = [];
const note = (m?: string) => {
  if (!m) return;
  pending.push(m);
  console.error(m);
};

// Returns a note when a running trace was saved (or lost) by the close. Waits for a launch in flight, then closes its browser.
function closeBrowser(): Promise<string | undefined> {
  const p = doClose().finally(() => {
    if (closing === p) closing = undefined;
  });
  return (closing = p);
}
// The close in flight, so `bye` can wait for a trace save that already cleared `s`.
let closing: Promise<string | undefined> | undefined;

async function doClose(): Promise<string | undefined> {
  if (launching) await launching.p.catch(() => {});
  const old = s;
  s = undefined;
  let note: string | undefined;
  if (old?.tracing) {
    old.tracing = false; // so the disconnect handler does not report it again
    try {
      note = `trace saved: ${saveTrace(await old.browser.stopTracing())}`;
    } catch (e) {
      note = `trace lost: ${e instanceof Error ? e.message : e}`;
    }
  }
  await old?.browser.close().catch(() => {});
  return note;
}

const emulate = async (n: Session, p: Page) => {
  if (n.viewport) await p.setViewportSize(n.viewport);
  if (n.colorScheme || n.media) await p.emulateMedia({ colorScheme: n.colorScheme, media: n.media });
};

function keep<T>(a: T[], x: T, n: Session, k: "consoleDropped" | "networkDropped") {
  a.push(x);
  if (a.length > CAP) (a.shift(), n[k]++);
}

async function launch(engine: "webkit" | "chromium", headed: boolean): Promise<Session> {
  const browser = await (engine === "webkit" ? webkit : chromium).launch({ headless: !headed, handleSIGINT: false, handleSIGTERM: false, handleSIGHUP: false }); // `bye` owns these: Playwright's handlers would kill the browser mid trace save
  let context: BrowserContext, page: Page;
  try {
    context = await browser.newContext({ bypassCSP: true });
    page = await context.newPage();
  } catch (e) {
    await browser.close().catch(() => {});
    throw e;
  }
  const n: Session = { engine, headed, browser, context, page, console: [], network: [], tracing: false, consoleDropped: 0, networkDropped: 0 };
  browser.on("disconnected", () => {
    if (n.tracing) note("trace lost: browser disconnected");
    n.tracing = false;
    if (s === n) s = undefined;
  });
  // Context-level listeners cover every tab, including ones opened by the page or by `run`.
  context.on("console", (m) => {
    const l = m.location();
    keep(n.console, `[${m.type()}] ${m.text()} (${l.url}:${l.lineNumber}:${l.columnNumber})`, n, "consoleDropped");
  });
  context.on("weberror", (w) => keep(n.console, `[pageerror] ${w.error().stack ?? w.error().message}`, n, "consoleDropped"));
  context.on("requestfinished", async (r) => {
    const res = await r.response().catch(() => null);
    keep(n.network, { req: r, sum: { method: r.method(), url: r.url(), status: res?.status(), resourceType: r.resourceType() } }, n, "networkDropped");
  });
  context.on("requestfailed", (r) =>
    keep(n.network, { req: r, sum: { method: r.method(), url: r.url(), resourceType: r.resourceType(), failure: r.failure()?.errorText } }, n, "networkDropped"),
  );
  // The newest tab becomes the one tools act on, as in a real browser.
  context.on("page", (p) => {
    n.page = p;
    emulate(n, p).catch(() => {}); // the tab may already be gone
  });
  return n;
}

function need(): Session {
  if (!s) throw new Error("no page open: call `open` first");
  if (s.page.isClosed()) {
    const open = s.context.pages().filter((p) => !p.isClosed());
    if (!open.length) throw new Error("every tab was closed: call `open` again");
    s.page = open[open.length - 1]!;
  }
  return s;
}

const text = (t: string) => ({ content: [{ type: "text" as const, text: trunc(t, 50000) }] });
// JSON is never cut mid-way: shrink long strings first, else return a valid object with a preview.
const capStr = (v: any, n: number): any =>
  typeof v === "string"
    ? v.length > n ? `${v.slice(0, n)}... (truncated, ${v.length} chars)` : v
    : Array.isArray(v)
      ? v.map((x) => capStr(x, n))
      : v && typeof v === "object"
        ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, capStr(x, n)]))
        : v;
const jsonText = (v: unknown, space?: number, max = 50000) => {
  let t = JSON.stringify(v, null, space) ?? "undefined";
  for (const n of [2000, 500, 100]) {
    if (t.length <= max) break;
    t = JSON.stringify(capStr(v, n), null, space);
  }
  return t.length <= max ? t : JSON.stringify({ truncated: true, note: `result too large (${t.length} chars)`, preview: t.slice(0, 2000) });
};
const idleMs = Number(process.env.BROWSER_MCP_IDLE_MS) || 600000;
let idle: ReturnType<typeof setTimeout> | undefined;
let inflight = 0;
const wrap = <A>(fn: (a: A) => Promise<{ content: any[] }>) => async (a: A) => {
  inflight++;
  clearTimeout(idle);
  let r: { isError?: boolean; content: any[] };
  try {
    r = await fn(a);
  } catch (e) {
    r = { isError: true, content: [{ type: "text" as const, text: e instanceof Error ? e.message : String(e) }] };
  } finally {
    inflight--;
    clearTimeout(idle);
    if (!inflight && s) idle = setTimeout(() => closeBrowser().then(note), idleMs);
  }
  if (pending.length) r.content = [{ type: "text" as const, text: pending.splice(0).join("\n") }, ...r.content];
  return r;
};

const chromiumOnly = () => {
  if (need().engine !== "chromium") throw new Error("chromium only: reopen with engine=chromium");
  return need();
};
const outFile = (kind: string, ext: string) => {
  const dir = process.env.BROWSER_MCP_OUT ?? join(tmpdir(), "browser-mcp");
  mkdirSync(dir, { recursive: true });
  return join(dir, `${kind}-${new Date().toISOString().replace(/[:.]/g, "-")}.${ext}`);
};
const saveTrace = (buf: Buffer) => {
  const path = outFile("trace", "json");
  writeFileSync(path, buf);
  return path;
};
const trunc = (t: string, n: number) => (t.length > n ? `${t.slice(0, n)}... (truncated, ${t.length} chars)` : t);

const BUILTIN = new Set(
  "Object Array Function String Number Boolean Map Set WeakMap WeakSet Promise RegExp Date Error ArrayBuffer DataView Symbol BigInt Proxy Int8Array Uint8Array Uint8ClampedArray Int16Array Uint16Array Int32Array Uint32Array Float32Array Float64Array BigInt64Array BigUint64Array (closure) (system) (compiled code) (array) (string) (number) (concatenated string) (sliced string)".split(" "),
);
const builtin = (n: string) =>
  BUILTIN.has(n) || /^(HTML|SVG|CSS|DOM|Window|Document|Text|Comment|Node|Event|system \/|v8)|Event$|Attr$| \((prototype|internal cache)\)/.test(n);

// Per-constructor [count, selfSize] over `object` and `closure` nodes, iterating the flat nodes array by stride.
function heapByName(raw: string): Map<string, [number, number]> {
  const snap = JSON.parse(raw);
  const fields: string[] = snap.snapshot.meta.node_fields;
  const types: string[] = snap.snapshot.meta.node_types[0];
  const strings: string[] = snap.strings;
  const nodes: number[] = snap.nodes;
  const stride = fields.length;
  const [t, nm, sz] = [fields.indexOf("type"), fields.indexOf("name"), fields.indexOf("self_size")];
  const object = types.indexOf("object");
  const closure = types.indexOf("closure");
  const out = new Map<string, [number, number]>();
  for (let i = 0; i < nodes.length; i += stride) {
    const ty = nodes[i + t]!;
    if (ty !== object && ty !== closure) continue;
    const name = ty === closure ? "(closure)" : strings[nodes[i + nm]!]!;
    const e = out.get(name);
    if (e) (e[0]++, (e[1] += nodes[i + sz]!));
    else out.set(name, [1, nodes[i + sz]!]);
  }
  return out;
}

const server = new McpServer({ name: "browser", version: "0.1.0" });

server.registerTool(
  "open",
  {
    description:
      "Navigate to a URL in a headless browser and return the final url, title and HTTP status as JSON, followed by the page's ARIA snapshot (truncated at 4000 chars), so look at it before acting. `engine` (webkit or chromium) and `headed` default to the running session's values, else webkit and headless; the browser relaunches (dropping the current page and its console/network logs; a running trace is saved and its path reported) only when a given value differs from the running one. Headed only so a human can look. `viewport`, `colorScheme` and `media` emulate before navigating and persist for later opens and new tabs (a popup opened by the page may briefly render before emulation applies); anything else (user agent, geolocation, offline, network or CPU throttling) goes through `run`.",
    inputSchema: {
      url: z.string(),
      engine: z.enum(["webkit", "chromium"]).optional(),
      headed: z.boolean().optional(),
      viewport: z.object({ width: z.number().int(), height: z.number().int() }).optional(),
      colorScheme: z.enum(["light", "dark", "no-preference"]).optional(),
      media: z.enum(["screen", "print"]).optional(),
    },
  },
  wrap(async ({ url, engine, headed, viewport, colorScheme, media }) => {
    const e = engine ?? s?.engine ?? "webkit";
    const h = headed ?? s?.headed ?? false;
    const key = `${e}/${h}`;
    let saved: string | undefined;
    let n: Session | undefined;
    // Serialized on the launch in flight: a different engine waits, then replaces it.
    while (!n) {
      const l = launching;
      if (l) {
        await l.p.catch(() => undefined); // another key's failed launch is not ours
        const got = l.key === key ? await l.p : undefined;
        if (!got) continue;
        if (s !== got) throw new Error("browser was closed during open");
        n = got;
      } else if (s && (s.engine !== e || s.headed !== h)) {
        saved = (await closeBrowser()) ?? saved;
      } else if (s) {
        n = s;
      } else {
        const p: Promise<Session> = launch(e, h)
          .then((x) => (s = x))
          .finally(() => {
            if (launching?.p === p) launching = undefined;
          });
        launching = { key, p };
      }
    }
    // Work on the local session: a concurrent close or disconnect clears the global.
    try {
      if (n.page.isClosed()) n.page = n.context.pages().find((p) => !p.isClosed()) ?? (await n.context.newPage());
      n.viewport = viewport ?? n.viewport;
      n.colorScheme = colorScheme ?? n.colorScheme;
      n.media = media ?? n.media;
      await emulate(n, n.page);
      const res = await n.page.goto(url, { waitUntil: "load" });
      const head = JSON.stringify({ url: n.page.url(), title: await n.page.title(), status: res?.status() ?? null });
      const tree = await n.page.locator("body").ariaSnapshot().then(
        (t) => (t.length > 4000 ? `${t.slice(0, 4000)}\n… (truncated, call snapshot for the full tree)` : t),
        (e) => `snapshot unavailable: ${e instanceof Error ? e.message : e}`,
      );
      return text(`${saved ? `${saved}\n` : ""}${head}\n\nsnapshot:\n${tree}`);
    } catch (err) {
      if (s !== n) throw new Error("browser was closed during open");
      throw err;
    }
  }),
);

server.registerTool(
  "close",
  { description: "Close the browser and drop its page and logs; a running trace is saved and its path reported. Errors when nothing was open.", inputSchema: {} },
  wrap(async () => {
    const was = !!s || !!launching;
    const saved = await closeBrowser();
    if (!was) return { isError: true, content: [{ type: "text" as const, text: "nothing was open" }] };
    return text(`closed${saved ? `\n${saved}` : ""}`);
  }),
);

server.registerTool(
  "snapshot",
  { description: "Accessibility snapshot (ARIA tree) of the current page as text.", inputSchema: {} },
  wrap(async () => text(await need().page.locator("body").ariaSnapshot())),
);

server.registerTool(
  "screenshot",
  { description: "PNG screenshot of the current page.", inputSchema: { fullPage: z.boolean().default(false) } },
  wrap(async ({ fullPage }) => {
    const png = await need().page.screenshot({ fullPage });
    return { content: [{ type: "image" as const, data: png.toString("base64"), mimeType: "image/png" }] };
  }),
);

server.registerTool(
  "console",
  {
    description: "Console messages and page errors collected since the page was created (type, text, location). Keeps the newest 1000; reports how many older ones were dropped.",
    inputSchema: { clear: z.boolean().default(false) },
  },
  wrap(async ({ clear }) => {
    const n = need();
    const c = n.console;
    const out = (n.consoleDropped ? `(${n.consoleDropped} older messages dropped)\n` : "") + (c.join("\n") || "(none)");
    if (clear) ((c.length = 0), (n.consoleDropped = 0));
    return text(out);
  }),
);

server.registerTool(
  "network",
  {
    description:
      "Newest 1000 requests collected since the page was created (older ones are dropped and counted in a leading note), each prefixed with its 1-based index into the current buffer, which shifts when old entries drop: method, url, status, resourceType, failure. `filter` is a substring match on url (indexes stay those of the full list). With `index`, full detail for that request: request/response headers, post data, timing, response body (text truncated to 20000 chars, binary as size and type).",
    inputSchema: { filter: z.string().optional(), index: z.number().int().min(1).optional(), clear: z.boolean().default(false) },
  },
  wrap(async ({ filter, index, clear }) => {
    const sess = need();
    const n = sess.network;
    let out: string;
    if (index) {
      const e = n[index - 1];
      if (!e) throw new Error(`no request at index ${index} (${n.length} collected)`);
      const { req } = e;
      const res = await req.response().catch(() => null);
      let body: string | undefined;
      if (res) {
        const buf = await res.body().catch((e) => e as Error);
        const type = (await res.allHeaders())["content-type"] ?? "";
        if (buf instanceof Error) body = `(unavailable: ${buf.message})`;
        else if (/^text\/|json|xml|javascript|svg|x-www-form-urlencoded/.test(type)) body = trunc(buf.toString("utf8"), 20000);
        else body = `(binary, ${buf.length} bytes, ${type || "unknown type"})`;
      }
      out = jsonText(
        {
          index,
          ...e.sum,
          requestHeaders: await req.allHeaders(),
          responseHeaders: await res?.allHeaders(),
          postData: req.postData() ?? undefined,
          timing: req.timing(),
          body,
        },
        1,
        49000,
      );
    } else {
      out = jsonText(
        n.flatMap((r, i) => (!filter || String(r.sum.url).includes(filter) ? [{ index: i + 1, ...r.sum }] : [])),
        1,
        49000,
      );
      if (sess.networkDropped) out = `(${sess.networkDropped} older requests dropped)\n${out}`;
    }
    if (clear) ((n.length = 0), (sess.networkDropped = 0));
    return text(out);
  }),
);

server.registerTool(
  "evaluate",
  {
    description:
      "Run JavaScript in the PAGE context, like the DevTools console (document, window, page globals); contrast `run`, which runs Playwright code in the server. `expression` is any script (statements allowed, the last statement's value is returned; use an async IIFE for `await`); its awaited result is returned JSON-serialized, DOM nodes and NodeLists as short descriptions.",
    inputSchema: { expression: z.string() },
  },
  wrap(async ({ expression }) => {
    const src = `(async () => {
      const d = (n) => "<" + n.tagName.toLowerCase() + (n.id ? "#" + n.id : "") + (n.classList.length ? "." + [...n.classList].join(".") : "") + "> " + JSON.stringify((n.textContent || "").trim().slice(0, 60));
      // Indirect eval: global scope and the last statement's value, like the console.
      const v = await (0, eval)(${JSON.stringify(expression)});
      try {
        const r = JSON.stringify(v, function (k, x) {
          if (x instanceof Element) return d(x);
          if (x instanceof Node) return "[" + x.nodeName + "]";
          if (x instanceof NodeList || x instanceof HTMLCollection) return { type: x.constructor.name, length: x.length, items: [...x].slice(0, 10).map((e) => e instanceof Element ? d(e) : "[" + e.nodeName + "]") };
          if (typeof x === "function") return "[function " + x.name + "]";
          if (typeof x === "bigint") return x.toString() + "n";
          return x;
        }, 1);
        return r === undefined ? "undefined" : r;
      } catch (e) { return String(v) + " (" + e.message + ")"; }
    })()`;
    const out = String(await need().page.evaluate(src));
    if (out.length > 50000) {
      try {
        return text(jsonText(JSON.parse(out), 1));
      } catch {} // not JSON: plain-text cut
    }
    return text(out);
  }),
);

server.registerTool(
  "dom",
  {
    description:
      "Inspect up to `limit` (default 5, max 20) elements matching a CSS `selector`: tag, attributes, bounding box, outerHTML (2000 chars), computed `styles` (requested property names, default display, position, visibility, width, height, color, background-color, font-size, z-index). On chromium also event listeners (type, capture, handler location); not available on webkit.",
    inputSchema: { selector: z.string(), styles: z.array(z.string()).optional(), limit: z.number().int().min(1).max(20).default(5) },
  },
  wrap(async ({ selector, styles, limit }) => {
    const { page, engine, context } = need();
    const props = styles?.length
      ? styles
      : ["display", "position", "visibility", "width", "height", "color", "background-color", "font-size", "z-index"];
    const els: any[] = await page.evaluate(
      ({ selector, props, limit }) =>
        [...document.querySelectorAll(selector)].slice(0, limit).map((e) => {
          const cs = getComputedStyle(e);
          const r = e.getBoundingClientRect();
          return {
            tag: e.tagName.toLowerCase(),
            attributes: Object.fromEntries([...e.attributes].map((a) => [a.name, a.value])),
            box: { x: r.x, y: r.y, width: r.width, height: r.height },
            html: e.outerHTML.length > 2000 ? e.outerHTML.slice(0, 2000) + "... (truncated)" : e.outerHTML,
            styles: Object.fromEntries(props.map((p) => [p, cs.getPropertyValue(p)])),
          };
        }),
      { selector, props, limit },
    );
    const total = await page.evaluate((q) => document.querySelectorAll(q).length, selector);
    if (engine === "chromium") {
      const cdp = await context.newCDPSession(page);
      try {
        const scripts: Record<string, { url: string; line: number; col: number }> = {};
        cdp.on("Debugger.scriptParsed", (e) => (scripts[e.scriptId] = { url: e.url, line: e.startLine, col: e.startColumn }));
        await cdp.send("Debugger.enable");
        await cdp.send("Debugger.setSkipAllPauses", { skip: true });
        for (const [i, el] of els.entries()) {
          const { result } = await cdp.send("Runtime.evaluate", {
            expression: `document.querySelectorAll(${JSON.stringify(selector)})[${i}]`,
          });
          if (!result.objectId) continue;
          const { listeners } = await cdp.send("DOMDebugger.getEventListeners", { objectId: result.objectId });
          el.listeners = [];
          for (const l of listeners) {
            const sc = scripts[l.scriptId];
            const rel = l.lineNumber - (sc?.line ?? 0);
            const col = l.columnNumber - (rel === 0 ? (sc?.col ?? 0) : 0);
            const src = await cdp.send("Debugger.getScriptSource", { scriptId: l.scriptId }).catch(() => undefined);
            el.listeners.push({
              type: l.type,
              useCapture: l.useCapture,
              once: l.once,
              passive: l.passive,
              location: `${sc?.url || "script " + l.scriptId}:${l.lineNumber + 1}:${l.columnNumber + 1}`,
              source: src?.scriptSource.split("\n")[rel]?.slice(Math.max(0, col - 40), col + 120),
            });
          }
        }
      } finally {
        await cdp.detach().catch(() => {});
      }
    }
    return text(jsonText({ matched: total, shown: els.length, listeners: engine === "chromium" ? undefined : "not available on webkit", elements: els }, 1));
  }),
);

server.registerTool(
  "performance",
  {
    description:
      "Page performance snapshot (both engines): navigation timing (TTFB, DOMContentLoaded, load), FCP, LCP with the LCP element (tag, id, url, size; WebKit's LCP can skip images, so measure LCP on chromium), CLS, long tasks, resources by type (count, transfer bytes), JS heap where exposed. On chromium also CDP Performance metrics (heap, nodes, layout/style recalc counts, script/task duration).",
    inputSchema: {},
  },
  wrap(async () => {
    const { page, engine, context } = need();
    const web = await page.evaluate(async () => {
      const r = (x: number | undefined) => (x === undefined ? undefined : Math.round(x * 10) / 10);
      const obs = (type: string) =>
        new Promise<PerformanceEntry[]>((res) => {
          try {
            const po = new PerformanceObserver((l) => (res(l.getEntries()), po.disconnect()));
            po.observe({ type, buffered: true });
            setTimeout(() => res([]), 300);
          } catch {
            res([]);
          }
        });
      const nav = performance.getEntriesByType("navigation")[0] as PerformanceNavigationTiming | undefined;
      const fcp = performance.getEntriesByName("first-contentful-paint")[0];
      const [lcp, cls, lt] = await Promise.all([obs("largest-contentful-paint"), obs("layout-shift"), obs("longtask")]);
      const byType: Record<string, { count: number; transferBytes: number }> = {};
      for (const e of performance.getEntriesByType("resource") as PerformanceResourceTiming[]) {
        const t = (byType[e.initiatorType || "other"] ??= { count: 0, transferBytes: 0 });
        t.count++;
        t.transferBytes += e.transferSize;
      }
      const mem = (performance as any).memory;
      return {
        navigation: nav && {
          ttfbMs: r(nav.responseStart),
          domContentLoadedMs: r(nav.domContentLoadedEventEnd),
          loadMs: r(nav.loadEventEnd),
        },
        fcpMs: r(fcp?.startTime),
        lcpMs: r(lcp.at(-1)?.startTime),
        // Which element was the LCP, so a measurement names it instead of leaving the agent to guess.
        lcpElement: ((e: any) =>
          e && {
            tag: e.element?.tagName?.toLowerCase(),
            id: e.element?.id || undefined,
            url: e.url || undefined,
            sizePx: e.size,
          })(lcp.at(-1)),
        cls: Math.round(cls.reduce((a, e: any) => a + (e.hadRecentInput ? 0 : e.value), 0) * 1000) / 1000,
        longTasks: { count: lt.length, totalMs: r(lt.reduce((a, e) => a + e.duration, 0)) },
        resources: byType,
        jsHeap: mem && { usedBytes: mem.usedJSHeapSize, totalBytes: mem.totalJSHeapSize },
      };
    });
    let cdpMetrics: Record<string, number> | undefined;
    if (engine === "chromium") {
      const cdp = await context.newCDPSession(page);
      try {
        await cdp.send("Performance.enable");
        const { metrics } = await cdp.send("Performance.getMetrics");
        const keep = ["JSHeapUsedSize", "JSHeapTotalSize", "Nodes", "LayoutCount", "RecalcStyleCount", "ScriptDuration", "TaskDuration"];
        cdpMetrics = Object.fromEntries(metrics.filter((m) => keep.includes(m.name)).map((m) => [m.name, m.value]));
      } finally {
        await cdp.detach().catch(() => {});
      }
    }
    return text(jsonText({ ...web, cdp: cdpMetrics }));
  }),
);

server.registerTool(
  "trace",
  {
    description:
      "Chromium only. `start` begins a Chrome performance trace (with screenshots); `stop` writes it to a file and returns path and size. Open the file in Chrome DevTools' Performance panel.",
    inputSchema: { action: z.enum(["start", "stop"]) },
  },
  wrap(async ({ action }) => {
    const c = chromiumOnly();
    if (action === "start") {
      if (c.tracing) throw new Error("trace already running: call trace stop first");
      await c.browser.startTracing(c.page, { screenshots: true });
      c.tracing = true;
      return text("tracing started");
    }
    if (!c.tracing) throw new Error("no trace running: call trace start first");
    c.tracing = false;
    const buf = await c.browser.stopTracing();
    const path = saveTrace(buf);
    return text(JSON.stringify({ path, bytes: buf.length, note: "open in Chrome DevTools, Performance panel (Load profile)" }));
  }),
);

server.registerTool(
  "heap_snapshot",
  {
    description:
      "Chromium only. Take a V8 heap snapshot of the page, write a .heapsnapshot file (open in DevTools Memory panel), return path, size, JS heap usage and node count, plus `top` constructors by instance count and `diff` versus the previous snapshot of this session (countDelta, sizeDelta), with `userClasses` (the page's own classes, what to look at first for a leak) separated from built-ins (`builtin: true`).",
    inputSchema: {},
  },
  wrap(async () => {
    const c = chromiumOnly();
    const { page, context } = c;
    const cdp = await context.newCDPSession(page);
    try {
      const chunks: string[] = [];
      cdp.on("HeapProfiler.addHeapSnapshotChunk", (e) => chunks.push(e.chunk));
      await cdp.send("HeapProfiler.enable");
      const usage = await cdp.send("Runtime.getHeapUsage");
      await cdp.send("HeapProfiler.takeHeapSnapshot", { reportProgress: false });
      const raw = chunks.join("");
      const path = outFile("heap", "heapsnapshot");
      writeFileSync(path, raw);
      const nodes = /"node_count":(\d+)/.exec(raw.slice(0, 8192))?.[1];
      const bytes = Buffer.byteLength(raw);
      const cur = heapByName(raw);
      const prev = c.heap;
      c.heap = cur;
      const mark = <T extends { name: string }>(r: T) => (builtin(r.name) ? { ...r, builtin: true } : r);
      const top = [...cur].sort((a, b) => b[1][0] - a[1][0]).slice(0, 15).map(([name, [count, size]]) => mark({ name, count, size }));
      const diff = prev
        ? [...cur]
            .map(([name, [count, size]]) => ({ name, countDelta: count - (prev.get(name)?.[0] ?? 0), sizeDelta: size - (prev.get(name)?.[1] ?? 0), count }))
            .filter((d) => d.countDelta || d.sizeDelta)
            .sort((a, b) => b.countDelta - a.countDelta)
            .slice(0, 15)
            .map(mark)
        : undefined;
      const userClasses = (diff ?? top).filter((r) => !("builtin" in r));
      return text(
        JSON.stringify({ path, bytes, heapUsedBytes: usage.usedSize, heapTotalBytes: usage.totalSize, nodeCount: nodes ? Number(nodes) : undefined, userClasses, top, diff }, null, 1),
      );
    } finally {
      await cdp.detach().catch(() => {});
    }
  }),
);

server.registerTool(
  "run",
  {
    description:
      "Escape hatch for anything else (click, type, wait, tracing, CDP via context.newCDPSession on chromium). `code` is the source of an async function like `async ({ page, context, browser }) => { ... }`; it is awaited and its JSON-serialized result returned. Runs arbitrary code in the server process.",
    inputSchema: { code: z.string() },
  },
  wrap(async ({ code }) => {
    const { page, context, browser } = need();
    const fn = (0, eval)(`(${code})`);
    const r = await fn({ page, context, browser });
    return text(jsonText(r, 1));
  }),
);

// Once, however many signals arrive; a hung close cannot block exit.
let down: Promise<void> | undefined;
const bye = () =>
  (down ??= Promise.race([(async () => (note(await closing?.catch(() => undefined)), note(await closeBrowser())))(), new Promise<void>((r) => setTimeout(r, 5000))])
    .catch(() => {})
    .finally(() => process.exit(0)));
process.stdin.on("end", bye);
for (const sig of ["SIGTERM", "SIGINT", "SIGHUP"]) process.on(sig, bye);

await server.connect(new StdioServerTransport());
