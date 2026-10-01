// Model-free stdio smoke test: spawns index.ts, calls every tool on both engines. Run: bun run smoke.ts
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { mkdtempSync, readdirSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const INDEX = join(import.meta.dir, "index.ts");
const OUT = mkdtempSync(join(tmpdir(), "browser-mcp-smoke-"));
let pass = 0;
let fails = 0;
const ok = (c: boolean, m: string) => {
  console.log(c ? "PASS" : "FAIL", m);
  c ? pass++ : fails++;
};
const size = (p: string) => {
  try {
    return statSync(p).size;
  } catch {
    return 0;
  }
};
const json = (t: string) => {
  try {
    return JSON.parse(t);
  } catch {
    return {};
  }
};

const page = `<title>T</title><style>#b{color:rgb(255,0,0);padding:4px}</style><h1>Hi</h1><a href=/x>a</a><a href=/y>b</a><button id=b>Go</button>
<script>
function neverCalled(){ debugger; }
console.log('hi');
document.getElementById('b').addEventListener('click', function clickme(){ console.log('clicked'); });
fetch('/api', { method: 'POST', body: 'p=1' }).then(r => r.json());
</script>`;
const srv = Bun.serve({
  port: 0,
  fetch(req) {
    const u = new URL(req.url);
    if (u.pathname === "/api") return Response.json({ hello: "world", n: [1, 2, 3] }, { headers: { "x-test": "yes" } });
    if (u.pathname === "/csp") return new Response("<title>C</title><h1>csp</h1>", { headers: { "content-type": "text/html", "content-security-policy": "script-src 'self'" } });
    return new Response(page, { headers: { "content-type": "text/html" } });
  },
});
const base = `http://localhost:${srv.port}/`;

// Descendants of a pid, via the process table (not a machine-wide pgrep).
function descendants(root: number): { pid: number; cmd: string }[] {
  const rows = Bun.spawnSync(["ps", "-axo", "pid=,ppid=,command="]).stdout.toString().split("\n");
  const all = rows.flatMap((l) => {
    const m = /^\s*(\d+)\s+(\d+)\s+(.*)$/.exec(l);
    return m ? [{ pid: +m[1]!, ppid: +m[2]!, cmd: m[3]! }] : [];
  });
  const out: { pid: number; cmd: string }[] = [];
  const todo = [root];
  while (todo.length) {
    const p = todo.pop()!;
    for (const r of all) if (r.ppid === p) (out.push(r), todo.push(r.pid));
  }
  return out;
}
const browsers = (pid: number) => descendants(pid).filter((d) => /ms-playwright/.test(d.cmd));

function mk(env: Record<string, string> = {}) {
  const c = new Client({ name: "smoke", version: "0" });
  const t = new StdioClientTransport({ command: "bun", args: ["run", INDEX], env: { ...(process.env as Record<string, string>), BROWSER_MCP_OUT: OUT, ...env } });
  const call = async (name: string, args: any = {}) => {
    const r: any = await c.callTool({ name, arguments: args });
    return { err: !!r.isError, t: r.content.map((x: any) => (x.type === "image" ? `<image ${x.data.length}b64>` : x.text)).join("\n") as string };
  };
  return { c, t, call };
}

const tools = ["open", "close", "snapshot", "screenshot", "console", "network", "evaluate", "dom", "performance", "trace", "heap_snapshot", "run"];
{
  const { c, t, call } = mk();
  await c.connect(t);
  const names = (await c.listTools()).tools.map((x) => x.name);
  ok(tools.every((x) => names.includes(x)), `tools listed: ${names.join(",")}`);

  for (const engine of ["webkit", "chromium"] as const) {
    console.log("=====", engine);
    let r = await call("close");
    ok(r.err && r.t === "nothing was open", `close before open is an error: ${r.t}`);
    r = await call("open", { url: base, engine, viewport: { width: 800, height: 600 }, colorScheme: "dark", media: "print" });
    ok(!r.err && r.t.includes('"status":200') && r.t.includes("snapshot:"), `open ${engine}`);
    await Bun.sleep(800);
    r = await call("evaluate", { expression: "[innerWidth, matchMedia('(prefers-color-scheme: dark)').matches, matchMedia('print').matches]" });
    ok(JSON.stringify(json(r.t)) === "[800,true,true]", `emulation applied: ${r.t.replace(/\s+/g, "")}`);
    r = await call("snapshot");
    ok(r.t.includes("Hi"), "snapshot");
    r = await call("screenshot");
    ok(r.t.startsWith("<image"), "screenshot");
    r = await call("console");
    ok(r.t.includes("[log] hi"), "console");
    r = await call("network");
    const list = json(r.t);
    const i = Array.isArray(list) ? list.find((e: any) => e.url.endsWith("/api"))?.index : undefined;
    ok(!!i, `network list (api index ${i})`);
    r = await call("network", { index: i });
    ok(r.t.includes('"x-test": "yes"') && r.t.includes("hello") && r.t.includes("p=1") && r.t.includes("requestHeaders"), "network index detail");
    r = await call("network", { index: 9999 });
    ok(r.err, "network bad index errors");
    r = await call("evaluate", { expression: "document.querySelectorAll('a').length" });
    ok(r.t === "2", `evaluate expression: ${r.t}`);
    r = await call("evaluate", { expression: "var a = 1; var b = 2; a + b" });
    ok(r.t === "3", `evaluate multi-statement: ${r.t}`);
    r = await call("evaluate", { expression: "document.querySelectorAll('a')" });
    ok(r.t.includes("NodeList") && r.t.includes("<a>"), "evaluate NodeList");
    r = await call("dom", { selector: "#b", styles: ["color", "padding-top"] });
    ok(r.t.includes("rgb(255, 0, 0)") && r.t.includes("4px"), "dom styles");
    if (engine === "chromium") ok(r.t.includes('"click"') && r.t.includes("clickme"), "dom click listener (debugger; statement did not hang it)");
    else ok(r.t.includes("not available on webkit"), "dom webkit note");
    let big = await call("dom", { selector: "a", limit: 21 }).catch((e) => ({ err: true, t: String(e) }));
    ok(big.err, `dom limit max enforced: ${big.t.slice(0, 80)}`);
    big = await call("evaluate", { expression: "Array.from({length: 5000}, (_, i) => ({ i, s: 'x'.repeat(100) }))" });
    ok(big.t.length <= 50000 && json(big.t).truncated === true, `huge JSON stays valid: ${big.t.length} chars`);
    big = await call("evaluate", { expression: "({ a: 1, s: 'y'.repeat(200000) })" });
    ok(big.t.length <= 50000 && json(big.t).a === 1, `long string shrunk, JSON valid: ${big.t.length} chars`);
    r = await call("performance");
    const p = json(r.t);
    ok(typeof p.navigation?.ttfbMs === "number", `performance ttfb=${p.navigation?.ttfbMs}`);
    if (engine === "chromium") ok(p.cdp?.Nodes > 0, "performance cdp metrics");

    if (engine === "webkit") {
      r = await call("trace", { action: "start" });
      ok(r.err && r.t.includes("chromium only"), `trace errors on webkit: ${r.t}`);
      r = await call("heap_snapshot");
      ok(r.err && r.t.includes("chromium only"), `heap_snapshot errors on webkit: ${r.t}`);
    } else {
      r = await call("trace", { action: "stop" });
      ok(r.err, `trace stop without start errors: ${r.t}`);
      r = await call("trace", { action: "start" });
      ok(!r.err, `trace start: ${r.t}`);
      await call("evaluate", { expression: "document.body.innerHTML += '<p>x</p>'" });
      r = await call("trace", { action: "stop" });
      ok(size(json(r.t).path) > 0, `trace file written: ${json(r.t).path}`);
      r = await call("heap_snapshot");
      let h = json(r.t);
      ok(size(h.path) > 0 && h.nodeCount > 0, `heap_snapshot 1 file ${size(h.path)} bytes, ${h.nodeCount} nodes`);
      await call("evaluate", { expression: "window.leak = Array.from({length: 500}, () => new (class Leaky { x = 1 })())" });
      r = await call("heap_snapshot");
      h = json(r.t);
      ok(size(h.path) > 0 && Array.isArray(h.diff) && h.diff.length > 0, `heap_snapshot 2 diff entries: ${h.diff?.length}`);
    }

    r = await call("run", { code: "async ({ page }) => ({ title: await page.title() })" });
    ok(json(r.t).title === "T", `run return value: ${r.t.replace(/\s+/g, "")}`);
    r = await call("run", { code: "async () => { console.log('to-stderr'); return 7; }" });
    ok(!r.err && r.t === "7", `run with console.log: ${r.t}`);
    r = await call("snapshot");
    ok(!r.err, "connection alive after console.log in run");
    r = await call("run", { code: `async ({ context }) => { const p = await context.newPage(); await p.goto(${JSON.stringify(base)}); return p.evaluate(() => [innerWidth, matchMedia('(prefers-color-scheme: dark)').matches, matchMedia('print').matches]); }` });
    ok(JSON.stringify(json(r.t)) === "[800,true,true]", `emulation persists to new tab: ${r.t.replace(/\s+/g, "")}`);
    r = await call("close");
    ok(r.t === "closed", `close: ${r.t}`);
    r = await call("close");
    ok(r.err && r.t === "nothing was open", `second close is an error: ${r.t}`);
    await Bun.sleep(500);
    ok(browsers(t.pid!).length === 0, `no browser process after close on ${engine}`);
  }

  console.log("===== persistence, CSP, trace on close");
  let r = await call("open", { url: base, engine: "chromium" });
  ok(!r.err, "open chromium");
  r = await call("open", { url: base });
  r = await call("trace", { action: "start" });
  ok(!r.err, "engine persists across open without engine (chromium-only trace starts)");
  r = await call("open", { url: `${base}csp` });
  ok(!r.err && r.t.includes("csp"), "open CSP page");
  r = await call("evaluate", { expression: "1 + 1" });
  ok(r.t === "2", `evaluate works under script-src 'self': ${r.t}`);
  r = await call("close");
  const saved = /trace saved: (.+)/.exec(r.t)?.[1];
  ok(!!saved && size(saved) > 0, `running trace saved on close: ${saved}`);
  r = await call("open", { url: base, engine: "chromium" });
  await call("trace", { action: "start" });
  r = await call("open", { url: base, engine: "webkit" });
  ok(/trace saved: /.test(r.t), "engine switch reports saved trace");
  await call("close");
  await c.close();
  await Bun.sleep(1000);
  ok(descendants(t.pid!).length === 0, "no descendants after client close");
}
{
  console.log("===== idle close");
  const { c, t, call } = mk({ BROWSER_MCP_IDLE_MS: "2000" });
  await c.connect(t);
  await call("open", { url: base, engine: "chromium" });
  ok(browsers(t.pid!).length > 0, "browser running after open");
  await Bun.sleep(1000);
  await call("snapshot");
  await Bun.sleep(1200);
  ok(browsers(t.pid!).length > 0, "still running 1.2s after last call (timer reset)");
  await Bun.sleep(2000);
  ok(browsers(t.pid!).length === 0, "browser gone ~3.2s after last call");
  const r = await call("snapshot");
  ok(r.err, `call after idle close errors: ${r.t}`);
  await c.close();
  await Bun.sleep(1000);
  ok(descendants(t.pid!).length === 0, "no leftover descendants at end");
}
{
  console.log("===== shutdown, launch races, close");
  {
    const { c, t, call } = mk();
    await c.connect(t);
    await call("open", { url: base, engine: "chromium" });
    await call("trace", { action: "start" });
    const before = readdirSync(OUT).filter((f) => f.startsWith("trace-")).length;
    const pid = t.pid!;
    const t0 = Date.now();
    (t as any)._process?.stdin?.end();
    process.kill(pid, "SIGTERM");
    while (Date.now() - t0 < 8000) {
      try {
        process.kill(pid, 0);
      } catch {
        break;
      }
      await Bun.sleep(100);
    }
    const dt = Date.now() - t0;
    let alive = true;
    try {
      process.kill(pid, 0);
    } catch {
      alive = false;
    }
    ok(!alive && dt < 6000, `double shutdown exits in ${dt}ms`);
    ok(readdirSync(OUT).filter((f) => f.startsWith("trace-")).length === before + 1, "trace saved by shutdown");
    await c.close().catch(() => {});
  }
  for (const sig of ["SIGTERM", "SIGHUP"] as const) {
    const { c, t, call } = mk();
    await c.connect(t);
    await call("open", { url: base, engine: "chromium" });
    await call("trace", { action: "start" });
    const before = readdirSync(OUT).filter((f) => f.startsWith("trace-")).length;
    const pid = t.pid!;
    const t0 = Date.now();
    // SIGTERM lands while the `close` tool is mid trace-save; SIGHUP hits a running trace.
    const cl = sig === "SIGTERM" ? call("close").catch(() => {}) : undefined;
    if (cl) await Bun.sleep(30);
    process.kill(pid, sig);
    while (Date.now() - t0 < 8000) {
      try {
        process.kill(pid, 0);
      } catch {
        break;
      }
      await Bun.sleep(100);
    }
    const dt = Date.now() - t0;
    let alive = true;
    try {
      process.kill(pid, 0);
    } catch {
      alive = false;
    }
    ok(!alive && dt < 6000, `${sig}${cl ? " during close" : ""} exits in ${dt}ms`);
    ok(readdirSync(OUT).filter((f) => f.startsWith("trace-")).length === before + 1, `trace saved (${sig})`);
    await cl;
    await c.close().catch(() => {});
    await Bun.sleep(500);
    ok(descendants(pid).length === 0, `no descendants after ${sig}`);
  }
  console.log("SKIP failing launch for one engine: Playwright has no per-engine executable override to simulate it cleanly");
  {
    const { c, t, call } = mk();
    await c.connect(t);
    const [a, b] = await Promise.all([call("open", { url: base, engine: "webkit" }), call("open", { url: base, engine: "chromium" })]);
    const r = await call("run", { code: "async ({ browser }) => browser.browserType().name()" });
    ok(!b.err && json(r.t) === "chromium", `concurrent opens: final engine ${r.t} (first open: ${a.err ? "error" : "ok"})`);
    await call("close");
    await c.close();
    await Bun.sleep(1000);
    ok(descendants(t.pid!).length === 0, "no descendants after concurrent opens");
  }
  {
    const { c, t, call } = mk();
    await c.connect(t);
    const o = call("open", { url: base, engine: "chromium" });
    await Bun.sleep(100);
    const cl = await call("close");
    await o;
    await Bun.sleep(500);
    ok(!cl.err && browsers(t.pid!).length === 0, `close during first open closes the browser: ${cl.t}`);
    const r = await call("snapshot");
    ok(r.err, "no page after close during open");
    await c.close();
  }
  console.log("SKIP popup emulation: documented in `open` (a popup may briefly render before emulation applies)");
}
srv.stop(true);
console.log(`\n${pass} passed, ${fails} failed`);
process.exit(fails ? 1 : 0);
