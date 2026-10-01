// Build the per-server pi agent templates with no model call.
//
// 1. `pi install npm:pi-mcp-adapter@3.3.0` into a fresh PI_CODING_AGENT_DIR.
// 2. Start pi in rpc mode with the run's exact flags and MCP config, send
//    get_commands, and keep stdin open until the adapter has written the server's
//    tools to mcp-cache.json (direct tools are registered from that cache, so the
//    first real run already has them). No prompt is sent, so no model is called.
//
// Usage: bun run parity/warm.ts [--server browser,chrome-devtools,safari] [--force] [--wait SECONDS]
// Templates go to $PARITY_TEMPLATES (default $TMPDIR/parity-templates/<server>).

import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { ADAPTER, SERVERS, killGroup, piArgs, piEnv, readCache, runGroup, sleep, templateDir, templatesRoot } from "./servers.ts";

const arg = (n: string) => (process.argv.includes(n) ? process.argv[process.argv.indexOf(n) + 1] : undefined);
const names = (arg("--server") ?? Object.keys(SERVERS).join(",")).split(",");
const force = process.argv.includes("--force");
const waitMs = Number(arg("--wait") ?? 90) * 1000;

let failed = false;
for (const name of names) {
  const def = SERVERS[name];
  if (!def) throw new Error(`unknown server ${name}`);
  const dir = templateDir(name);
  if (force) rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
  console.log(`[${name}] template ${dir}`);

  if (!existsSync(join(dir, "npm/node_modules/pi-mcp-adapter/index.ts"))) {
    const r = spawnSync("pi", ["install", ADAPTER], { env: piEnv(dir), encoding: "utf8" });
    if (r.status !== 0) {
      console.log(`[${name}] pi install failed:\n${r.stdout}${r.stderr}`);
      failed = true;
      continue;
    }
  }

  const log = join(tmpdir(), "parity-warm");
  mkdirSync(log, { recursive: true });
  const p = runGroup("pi", piArgs("rpc", dir, def.config), {
    env: piEnv(dir),
    cwd: dir,
    stdout: join(log, `${name}.out`),
    stderr: join(log, `${name}.err`),
    timeoutMs: waitMs + 30_000,
    stdin: "pipe",
  });
  p.child.stdin!.write(JSON.stringify({ id: "warm", type: "get_commands" }) + "\n");
  const end = Date.now() + waitMs;
  let tools: string[] = [];
  while (Date.now() < end) {
    await sleep(500);
    tools = (readCache(dir)?.servers[name]?.tools ?? []).map((t) => t.name);
    if (tools.length) break;
  }
  await sleep(2000); // let the adapter finish writing
  p.child.stdin!.end();
  const done = await Promise.race([p, sleep(8000).then(() => undefined)]);
  if (!done) killGroup(p.child.pid);
  tools = (readCache(dir)?.servers[name]?.tools ?? []).map((t) => t.name);
  console.log(`[${name}] mcp-cache.json: ${tools.length} tools${tools.length ? `: ${tools.join(", ")}` : ""}`);
  if (!tools.length) failed = true;
}
console.log(`templates root: ${templatesRoot()}`);
process.exit(failed ? 1 : 0);
