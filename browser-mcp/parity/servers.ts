// Shared by warm.ts and run.ts: the servers under test, the exact pi command, and process helpers.

import { spawn, spawnSync } from "node:child_process";
import { closeSync, openSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

export const PARITY_DIR = import.meta.dir;
export const ADAPTER = "npm:pi-mcp-adapter@3.3.0";
export const PROVIDER = "openai-codex";
export const MODEL = "gpt-6-luna";
export const THINKING = "medium";
export const TIMEOUT_MS = 300_000;

export interface ServerDef {
  name: string;
  /** MCP config file handed to pi with --mcp-config. The cache hash depends on it, so warm and run use the same file. */
  config: string;
  /** Matches the MCP server process, killed between runs. */
  serverProc: RegExp;
  /** Matches browser processes the server starts; null when they cannot be told apart from the user's own. */
  browserProc: RegExp | null;
  /** Why browserProc is null. */
  cleanupNote?: string;
}

// The browser config names this checkout's server by absolute path, so it is generated
// (and gitignored) rather than tracked. Same content every run, so the adapter's cache hash holds.
const browserConfig = join(PARITY_DIR, "mcp", "browser.generated.json");
writeFileSync(
  browserConfig,
  JSON.stringify(
    {
      settings: { directTools: true, scriptMode: false, namespaceProxyTools: false, notifyOnStartupConnect: false },
      mcpServers: { browser: { command: "bun", args: ["run", join(dirname(PARITY_DIR), "index.ts")] } },
    },
    null,
    2,
  ) + "\n",
);

export const SERVERS: Record<string, ServerDef> = {
  browser: {
    name: "browser",
    config: browserConfig,
    serverProc: /browser-mcp\/index\.ts/,
    browserProc: /ms-playwright/,
  },
  "chrome-devtools": {
    name: "chrome-devtools",
    config: join(PARITY_DIR, "mcp", "chrome-devtools.json"),
    serverProc: /chrome-devtools-mcp/,
    // --isolated gives puppeteer a fresh temp profile named puppeteer_dev_chrome_profile-*.
    browserProc: /puppeteer_dev_chrome_profile/,
  },
  safari: {
    name: "safari",
    config: join(PARITY_DIR, "mcp", "safari.json"),
    serverProc: /safaridriver --mcp/,
    browserProc: null,
    cleanupNote: "safaridriver drives the user's own Safari, so a leftover Safari window cannot be told apart from one the user opened",
  },
};

export const templatesRoot = () => process.env.PARITY_TEMPLATES ?? join(tmpdir(), "parity-templates");
export const templateDir = (server: string) => join(templatesRoot(), server);

/** The shared pi flags. `mode` is json for runs and rpc for warming. Prompt goes last, for json only. */
export function piArgs(mode: "json" | "rpc", agentDir: string, configPath: string, prompt?: string): string[] {
  return [
    "--mode", mode,
    ...(mode === "json" ? ["-p"] : []),
    "--no-session", "--offline", "--no-approve", "--no-extensions",
    "-e", join(agentDir, "npm/node_modules/pi-mcp-adapter/index.ts"),
    "--no-skills", "--no-prompt-templates", "--no-themes", "--no-context-files",
    "--mcp-config", configPath,
    "--provider", PROVIDER, "--model", MODEL, "--thinking", THINKING,
    ...(prompt === undefined ? [] : [prompt]),
  ];
}

export function piEnv(agentDir: string): Record<string, string> {
  return { ...(process.env as Record<string, string>), PI_MCP_CONFIG_MODE: "exclusive", PI_CODING_AGENT_DIR: agentDir };
}

export const shQuote = (s: string) => (/^[\w@%+=:,./-]+$/.test(s) ? s : `'${s.replaceAll("'", `'\\''`)}'`);

export interface ProcResult { exitCode: number | null; timedOut: boolean }

/** Run a command in its own process group with stdout/stderr to files; SIGKILL the whole group on timeout. */
export function runGroup(
  cmd: string,
  args: string[],
  o: {
    env: Record<string, string>;
    cwd: string;
    stdout: string;
    stderr: string;
    timeoutMs: number;
    stdin?: "ignore" | "pipe";
    /** Called every second while the child runs, and never after it exits. */
    onSample?: (pid: number) => void;
    /** Called once, `graceMs` after the child exits and before the group is killed, to see what survived it. */
    onGrace?: () => void;
    graceMs?: number;
  },
): Promise<ProcResult> & { child: ReturnType<typeof spawn> } {
  const out = openSync(o.stdout, "w");
  const err = openSync(o.stderr, "w");
  const child = spawn(cmd, args, { env: o.env, cwd: o.cwd, stdio: [o.stdin ?? "ignore", out, err], detached: true });
  closeSync(out);
  closeSync(err);
  const p = new Promise<ProcResult>((resolve) => {
    let timedOut = false;
    const t = setTimeout(() => {
      timedOut = true;
      killGroup(child.pid);
    }, o.timeoutMs);
    const tick = o.onSample && child.pid ? setInterval(() => o.onSample!(child.pid!), 1000) : undefined;
    child.on("close", async (code) => {
      clearTimeout(t);
      // Stop sampling: the pid may be reused once the child is gone, and the 1 s ticks already recorded its tree.
      clearInterval(tick);
      if (o.onGrace) {
        await sleep(o.graceMs ?? 1500);
        o.onGrace();
      }
      // pi's children share the group; make sure none outlive the run.
      killGroup(child.pid);
      resolve({ exitCode: timedOut ? 124 : code, timedOut });
    });
    child.on("error", () => {
      clearTimeout(t);
      clearInterval(tick);
      resolve({ exitCode: 127, timedOut: false });
    });
  });
  return Object.assign(p, { child });
}

export function killGroup(pid: number | undefined) {
  if (!pid) return;
  try {
    process.kill(-pid, "SIGKILL");
  } catch {}
}

export interface Proc { pid: number; cmd: string }

export function listProcs(pattern: RegExp): Proc[] {
  const out = spawnSync("ps", ["-axo", "pid=,command="], { encoding: "utf8", maxBuffer: 64 << 20 }).stdout;
  return out
    .split("\n")
    .map((l) => /^\s*(\d+)\s+(.*)$/.exec(l))
    .filter((m): m is RegExpExecArray => !!m)
    .map((m) => ({ pid: Number(m[1]), cmd: m[2]! }))
    .filter((p) => p.pid !== process.pid && pattern.test(p.cmd) && !/\bps -axo\b/.test(p.cmd));
}

/** Every live process below `root` by ppid. Playwright launches browsers detached, so they are children by ppid but not in the process group. */
export function descendants(root: number): Proc[] {
  const out = spawnSync("ps", ["-axo", "pid=,ppid=,command="], { encoding: "utf8", maxBuffer: 64 << 20 }).stdout;
  const kids = new Map<number, Proc[]>();
  for (const l of out.split("\n")) {
    const m = /^\s*(\d+)\s+(\d+)\s+(.*)$/.exec(l);
    if (!m || /\bps -axo\b/.test(m[3]!)) continue;
    const ppid = Number(m[2]);
    (kids.get(ppid) ?? kids.set(ppid, []).get(ppid)!).push({ pid: Number(m[1]), cmd: m[3]! });
  }
  const found: Proc[] = [];
  const todo = [root];
  while (todo.length) for (const k of kids.get(todo.pop()!) ?? []) found.push(k), todo.push(k.pid);
  return found;
}

export function isAlive(pid: number) {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

/**
 * The processes one spawned command has started, remembered across samples: once the
 * parent dies its children are reparented and the ppid walk no longer finds them.
 * Only ever touches descendants of `root`, so other live sessions of the same MCP server are left alone.
 */
export class ProcTree {
  seen = new Map<number, string>();
  sample(root: number) {
    for (const p of descendants(root)) this.seen.set(p.pid, p.cmd);
  }
  alive(pattern?: RegExp): Proc[] {
    return [...this.seen].filter(([pid, cmd]) => isAlive(pid) && (!pattern || pattern.test(cmd))).map(([pid, cmd]) => ({ pid, cmd }));
  }
  /** Kills what `sample` recorded, but only a pid whose current command is still the recorded one and still matches `patterns`, so a reused pid is left alone. */
  killAll(...patterns: (RegExp | null)[]) {
    const pats = patterns.filter((p): p is RegExp => !!p);
    const now = new Map(listProcs(/.*/).map((p) => [p.pid, p.cmd]));
    for (const p of this.alive()) {
      const cur = now.get(p.pid);
      if (cur !== p.cmd || !pats.some((re) => re.test(cur))) continue;
      try {
        process.kill(p.pid, "SIGKILL");
      } catch {}
    }
  }
}

export function readCache(dir: string): { servers: Record<string, { tools?: { name: string }[] }> } | undefined {
  try {
    return JSON.parse(readFileSync(join(dir, "mcp-cache.json"), "utf8"));
  } catch {
    return undefined;
  }
}

export const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));
