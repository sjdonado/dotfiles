// Model-free check: fixture server + `browser` MCP server over stdio + every
// scenario's reference solution, then its oracles. No model, no network beyond
// localhost. All scenarios must pass.
//
// Usage: bun run parity/verify.ts [--only id,id]

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { startFixtures } from "./fixtures.ts";
import { check, scenarios, type CalledTool, type RefCtx, type ToolResult } from "./scenarios.ts";
import { ProcTree } from "./servers.ts";

const INDEX = join(import.meta.dir, "..", "index.ts");
const only = process.argv.includes("--only") ? process.argv[process.argv.indexOf("--only") + 1]!.split(",") : undefined;
const work = mkdtempSync(join(tmpdir(), "parity-verify-"));
const file = join(work, "upload.txt");
writeFileSync(file, "UPLOAD-PAYLOAD-9\n");

const fx = startFixtures();
const client = new Client({ name: "parity-verify", version: "0" });
const transport = new StdioClientTransport({
  command: "bun",
  args: ["run", INDEX],
  env: { ...(process.env as Record<string, string>), BROWSER_MCP_OUT: join(work, "out") },
  stderr: "inherit",
});
await client.connect(transport);
const serverPid = transport.pid!;

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/** Tool calls in pi's naming (`browser_close`), for the toolCall oracle. */
let calls: CalledTool[] = [];

async function tool(name: string, args: Record<string, unknown> = {}): Promise<ToolResult> {
  const r: any = await client.callTool({ name, arguments: args }, undefined, { timeout: 60000 });
  calls.push({ name: `browser_${name}`, isError: !!r.isError });
  return {
    isError: !!r.isError,
    text: (r.content as any[]).filter((x) => x.type === "text").map((x) => x.text).join("\n"),
    images: (r.content as any[]).filter((x) => x.type === "image").map((x) => ({ data: x.data, mimeType: x.mimeType })),
  };
}

const ctx: RefCtx = {
  base: fx.base,
  file,
  tool,
  async text(name, args) {
    const r = await tool(name, args);
    if (r.isError) throw new Error(`${name} failed: ${r.text}`);
    return r.text;
  },
  async open(path, engine = "webkit") {
    return JSON.parse((await ctx.text("open", { url: fx.base + path, engine })).split("\n")[0]!);
  },
  async run(fn, arg) {
    const code = `async ({ page, context, browser }) => (${fn.toString()})({ page, context, browser }, ${JSON.stringify(arg ?? null)})`;
    const t = await ctx.text("run", { code });
    return t === "undefined" ? undefined : JSON.parse(t);
  },
  async evaluate(expression) {
    const t = await ctx.text("evaluate", { expression });
    return t === "undefined" ? undefined : JSON.parse(t);
  },
  async poll(fn, ms = 8000) {
    const end = Date.now() + ms;
    for (;;) {
      const v = await fn();
      if (v) return v;
      if (Date.now() > end) throw new Error("poll timed out");
      await sleep(200);
    }
  },
  sleep,
};

// Only browsers below the server this script spawned count, never another session's.
const tree = new ProcTree();
const leftover = () => {
  tree.sample(serverPid);
  return tree.alive(/ms-playwright/).length;
};

interface Row { id: string; pass: boolean; ms: number; detail: string; answer: string }
const rows: Row[] = [];

for (const s of scenarios) {
  if (only && !only.includes(s.id)) continue;
  fx.reset();
  calls = [];
  const t0 = Date.now();
  let answer = "";
  let detail = "";
  let pass = false;
  try {
    answer = await s.reference(ctx);
    if (s.leftover) {
      // Informational, as in the runner; the pass/fail signal is the toolCall oracle.
      const end = Date.now() + 5000;
      while (leftover() && Date.now() < end) await sleep(250);
      if (leftover()) console.log(`  (info) ${s.id}: browser process alive 5 s after the reference`);
    } else await tool("close");
    const res = check(s, answer, fx.log, calls, "browser");
    const bad = res.filter((r) => !r.pass);
    pass = bad.length === 0 && !detail;
    detail += bad.map((r) => `${r.kind}:${r.name}`).join(", ");
    if (!pass) detail += ` | answer=${JSON.stringify(answer)} log=${JSON.stringify(fx.log.map((e) => `${e.event} ${e.value}`))}`;
  } catch (e) {
    detail = `reference threw: ${e instanceof Error ? e.message : String(e)}`;
    await tool("close").catch(() => {});
  }
  const row = { id: s.id, pass, ms: Date.now() - t0, detail, answer };
  rows.push(row);
  console.log(`${pass ? "PASS" : "FAIL"} ${s.id.padEnd(20)} ${String(row.ms).padStart(6)} ms  ${pass ? row.answer.slice(0, 90) : detail}`);
}

await tool("close").catch(() => {});
await client.close().catch(() => {});
fx.stop();
await sleep(1000);
const left = leftover();

const passed = rows.filter((r) => r.pass).length;
console.log(`\n${passed}/${rows.length} reference solutions pass`);
console.log(`browser processes left after verify: ${left}`);
process.exit(passed === rows.length && left === 0 && (only || rows.length === scenarios.length) ? 0 : 1);
