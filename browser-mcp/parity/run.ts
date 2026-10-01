// The paid runner: one isolated pi run per scenario per server.
//
//   bun run parity/run.ts --server chrome-devtools|safari|browser [--only id,id] [--batch DIR] [--dry]
//
// Every run gets a fresh fixture server, a fresh working directory holding
// upload.txt, and a fresh copy of the server's warmed pi agent template (build
// it first with parity/warm.ts). Prompts name no tool, server or engine.
// --dry does everything except invoke pi and prints the exact command.

import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join } from "node:path";
import { fixtureFingerprint, startFixtures } from "./fixtures.ts";
import { check, render, scenarios, type OracleResult, type Scenario } from "./scenarios.ts";
import { MODEL, PARITY_DIR, PROVIDER, SERVERS, TIMEOUT_MS, ProcTree, piArgs, piEnv, runGroup, shQuote, templateDir } from "./servers.ts";

const arg = (n: string) => (process.argv.includes(n) ? process.argv[process.argv.indexOf(n) + 1] : undefined);
const serverName = arg("--server");
const found = serverName ? SERVERS[serverName] : undefined;
if (!found) {
  console.error("usage: bun run parity/run.ts --server chrome-devtools|safari|browser [--only id,id] [--batch DIR] [--dry]");
  process.exit(2);
}
const def = found;
const dry = process.argv.includes("--dry");
const only = arg("--only")?.split(",");
const unknown = (only ?? []).filter((id) => !scenarios.some((s) => s.id === id));
if (unknown.length) throw new Error(`unknown scenario ids: ${unknown.join(", ")}`);
const batch = arg("--batch") ?? join(PARITY_DIR, "runs", new Date().toISOString().replace(/[:.]/g, "-"));
const outRoot = join(batch, def.name);
const tpl = templateDir(def.name);
if (!dry && !existsSync(join(tpl, "npm/node_modules/pi-mcp-adapter/index.ts"))) {
  throw new Error(`no warmed template at ${tpl}: run \`bun run parity/warm.ts --server ${def.name}\` first`);
}

// ------------------------------------------------------------ pi events

interface ToolCall { name: string; args: unknown; isError?: boolean; resultBytes?: number }
interface Parsed {
  answer: string;
  toolCalls: ToolCall[];
  usage: Record<string, number>;
  stopReason?: string;
  errorMessage?: string;
  started: boolean;
  settled: boolean;
  turns: number;
}

/** pi --mode json exits 0 on model failure, so the verdict comes from the event stream. */
function parseEvents(path: string): Parsed {
  const p: Parsed = { answer: "", toolCalls: [], usage: {}, started: false, settled: false, turns: 0 };
  const open = new Map<string, ToolCall>();
  const add = (k: string, v: number) => (p.usage[k] = (p.usage[k] ?? 0) + v);
  for (const line of readFileSync(path, "utf8").split("\n")) {
    if (!line.trim()) continue;
    let e: any;
    try {
      e = JSON.parse(line);
    } catch {
      continue;
    }
    switch (e.type) {
      case "agent_start": p.started = true; break;
      case "agent_settled": p.settled = true; break;
      case "turn_end": p.turns++; break;
      case "tool_execution_start": {
        const c: ToolCall = { name: e.toolName, args: e.args };
        p.toolCalls.push(c);
        open.set(e.toolCallId, c);
        break;
      }
      case "tool_execution_end": {
        const c = open.get(e.toolCallId) ?? (p.toolCalls.push({ name: e.toolName, args: undefined }), p.toolCalls.at(-1)!);
        c.isError = !!e.isError;
        c.resultBytes = ((e.result?.content ?? []) as any[]).reduce((n, x) => n + Buffer.byteLength(x.text ?? "") + (x.data?.length ?? 0), 0);
        break;
      }
      case "message_end": {
        const m = e.message;
        if (m?.role !== "assistant") break;
        for (const [k, v] of Object.entries(m.usage ?? {})) {
          if (typeof v === "number") add(k, v);
          else if (v && typeof v === "object") for (const [k2, v2] of Object.entries(v)) if (typeof v2 === "number") add(`${k}.${k2}`, v2);
        }
        p.stopReason = m.stopReason;
        if (m.errorMessage) p.errorMessage = m.errorMessage;
        const text = ((m.content ?? []) as any[]).filter((x) => x.type === "text").map((x) => x.text).join("");
        if (text) p.answer = text;
        break;
      }
    }
  }
  return p;
}

function statusOf(exitCode: number | null, timedOut: boolean, p: Parsed): string {
  if (timedOut) return "timeout";
  if (p.stopReason === "error" || p.stopReason === "aborted") return "failed";
  if (exitCode !== 0) return "failed";
  return p.started && p.settled && p.stopReason === "stop" ? "completed" : "incomplete";
}

// ------------------------------------------------------------ one run

interface Row {
  id: string;
  server: string;
  pass: boolean;
  status: string;
  stopReason?: string;
  oracles: OracleResult[];
  /** Informational only, never part of `pass`: browser processes still alive 1.5 s after pi exited, sampled before the group kill. */
  leftover: { alive: number | null; detail: string } | null;
  toolCalls: number;
  usage: Record<string, number>;
  ms: number;
}

async function runOne(s: Scenario): Promise<Row> {
  const dir = join(outRoot, s.id);
  mkdirSync(dir, { recursive: true });
  const fx = startFixtures();
  const work = realpathSync(mkdtempSync(join(tmpdir(), "parity-work-")));
  const file = join(work, "upload.txt");
  writeFileSync(file, "UPLOAD-PAYLOAD-9\n");
  const prompt = render(s, fx.base, file);
  writeFileSync(join(dir, "prompt.txt"), prompt + "\n");

  const agent = mkdtempSync(join(tmpdir(), "parity-agent-"));
  if (existsSync(tpl)) {
    // -c clones on APFS, so a fresh copy of the template per run is cheap.
    if (spawnSync("cp", ["-cR", `${tpl}/.`, agent]).status !== 0) spawnSync("cp", ["-R", `${tpl}/.`, agent]);
  }
  rmSync(join(agent, "auth.json"), { force: true });
  const auth = join(homedir(), ".pi/agent/auth.json");
  if (existsSync(auth)) symlinkSync(auth, join(agent, "auth.json"));

  const args = piArgs("json", agent, def.config, prompt);
  const command = `cd ${shQuote(work)} && PI_MCP_CONFIG_MODE=exclusive PI_CODING_AGENT_DIR=${shQuote(agent)} pi ${args.map(shQuote).join(" ")} < /dev/null`;
  writeFileSync(join(dir, "command.txt"), command + "\n");

  const started = Date.now();
  let row: Row;
  if (dry) {
    console.log(`[dry] ${s.id}\n${command}\n`);
    row = { id: s.id, server: def.name, pass: false, status: "dry", oracles: [], leftover: null, toolCalls: 0, usage: {}, ms: 0 };
  } else {
    const tree = new ProcTree();
    const events = join(dir, "events.jsonl");
    let leftover: Row["leftover"] = null;
    const res = await runGroup("pi", args, {
      env: piEnv(agent),
      cwd: work,
      stdout: events,
      stderr: join(dir, "stderr.txt"),
      timeoutMs: TIMEOUT_MS,
      onSample: (pid) => tree.sample(pid),
      // Measured 1.5 s after pi exits, before the group kill.
      onGrace: () => {
        if (!s.leftover) return;
        if (!def.browserProc) leftover = { alive: null, detail: `n/a: ${def.cleanupNote}` };
        else {
          const n = tree.alive(def.browserProc).length;
          leftover = { alive: n, detail: `informational: ${n ? `${n} browser process(es) alive 1.5 s after pi exited` : "no browser process alive 1.5 s after pi exited"}` };
        }
      },
    });
    const ms = Date.now() - started;
    const parsed = parseEvents(events);
    const status = statusOf(res.exitCode, res.timedOut, parsed);

    tree.killAll(def.serverProc, def.browserProc);

    const oracles = check(s, parsed.answer, fx.log, parsed.toolCalls, def.name);
    const pass = status === "completed" && oracles.every((o) => o.pass);
    writeFileSync(join(dir, "fixture-log.json"), JSON.stringify(fx.log, null, 2));
    row = { id: s.id, server: def.name, pass, status, stopReason: parsed.stopReason, oracles, leftover, toolCalls: parsed.toolCalls.length, usage: parsed.usage, ms };
    writeFileSync(
      join(dir, "result.json"),
      JSON.stringify(
        { ...row, exitCode: res.exitCode, model: `${PROVIDER}/${MODEL}`, fixtureFingerprint: fixtureFingerprint(s.id, s.prompt), errorMessage: parsed.errorMessage, turns: parsed.turns, answer: parsed.answer, toolCallLog: parsed.toolCalls },
        null,
        2,
      ),
    );
  }
  fx.stop();
  rmSync(agent, { recursive: true, force: true });
  rmSync(work, { recursive: true, force: true });
  return row;
}

// ------------------------------------------------------------ main

const rows: Row[] = [];
for (const s of scenarios) {
  if (only && !only.includes(s.id)) continue;
  const r = await runOne(s);
  rows.push(r);
  if (!dry) {
    const why = r.oracles.filter((o) => !o.pass).map((o) => `${o.kind}:${o.name}`).join(", ");
    console.log(`${r.pass ? "PASS" : "FAIL"} ${r.id.padEnd(20)} ${r.status.padEnd(10)} ${String(Math.round(r.ms / 1000)).padStart(4)}s  calls=${String(r.toolCalls).padStart(2)}  ${r.leftover ? `leftover(info)=${r.leftover.alive ?? "n/a"} ` : ""}${why}`);
  }
}

if (!dry) {
  const total: Record<string, number> = {};
  for (const r of rows) for (const [k, v] of Object.entries(r.usage)) total[k] = (total[k] ?? 0) + v;
  const passed = rows.filter((r) => r.pass).length;
  writeFileSync(join(outRoot, "summary.json"), JSON.stringify({ server: def.name, model: `${PROVIDER}/${MODEL}`, passed, total: rows.length, usage: total, rows }, null, 2));
  console.log(`\n${def.name}: ${passed}/${rows.length} passed, ${rows.reduce((n, r) => n + r.toolCalls, 0)} tool calls, usage ${JSON.stringify(total)}`);
  console.log(`summary: ${join(outRoot, "summary.json")}`);
}
