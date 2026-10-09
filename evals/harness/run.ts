// Bun + JSON, no packages. Only --run starts paid Pi sessions.
import { appendFileSync, chmodSync, cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { materialize, sourceHashes, DEFAULT_SKILLS } from "./inputs";

const ROOT = resolve(import.meta.dir), CONFIG = join(ROOT, "scenarios.json");
const TIMEOUT_MS = 300_000;
type Assert = { type: string; value?: string; threshold?: number };
type Test = { description: string; vars: { fixture: string; request: string }; assert: Assert[] };
type Provider = { id: string; label: string; config: { model: string; model_reasoning_effort?: string } };
type Config = { providers: Provider[]; tests: Test[]; defaultTest?: { assert?: Assert[] } };
const save = (path: string, value: unknown) => writeFileSync(path, JSON.stringify(value, null, 2) + "\n");

export function sh(dir: string, cmd: string[], env = process.env): string {
  const p = Bun.spawnSync(cmd, { cwd: dir, env, stdout: "pipe", stderr: "pipe" });
  if (p.exitCode !== 0) throw new Error(`${cmd.join(" ")}: ${p.stderr.toString().trim() || `exit ${p.exitCode}`}`);
  return p.stdout.toString();
}

export function select(cfg: Config, pattern?: string) {
  if (!cfg.providers?.length || cfg.providers.some(p => p.id !== "openai:codex-sdk" || !p.config?.model || !/^[\w-]+$/.test(p.label)))
    throw new Error("Empty or unsupported providers; use labeled openai:codex-sdk providers with a model");
  const filter = pattern === undefined ? null : new RegExp(pattern);
  const tests = cfg.tests.filter(t => !filter || filter.test(t.description));
  if (!tests.length) throw new Error("No scenarios selected");
  return { tests, providers: cfg.providers };
}

export function parsePi(jsonl: string) {
  let text = "", usage: Record<string, number> = {}, missingUsage = false, messages = 0, settled = false, stopReason = "";
  const tools: string[] = [], commands: string[] = [], successfulCommands: string[] = [], errors: string[] = [], reads = new Set<string>(), pending = new Map<string, any>();
  for (const line of jsonl.split("\n")) {
    if (!line.trim()) continue;
    const e = JSON.parse(line);
    if (e.type === "agent_settled") settled = true;
    if (e.type === "message_end" && e.message?.role === "assistant") {
      messages++;
      text = (e.message.content ?? []).filter((c: any) => c.type === "text").map((c: any) => c.text).join("") || text;
      stopReason = e.message.stopReason;
      if (["error", "aborted"].includes(stopReason)) errors.push(e.message.errorMessage || stopReason);
      const numbers = Object.entries(e.message.usage ?? {}).filter(([_, v]) => typeof v === "number");
      if (!numbers.length) missingUsage = true;
      for (const [k, v] of numbers) usage[k] = (usage[k] ?? 0) + (v as number);
    } else if (e.type === "tool_execution_start") pending.set(e.toolCallId, e);
    else if (e.type === "tool_execution_end") {
      tools.push(String(e.toolName));
      const start = pending.get(e.toolCallId);
      pending.delete(e.toolCallId);
      if (start?.toolName === "bash" && e.toolName === "bash" && typeof start.args?.command === "string") {
        commands.push(start.args.command);
        if (!e.isError) successfulCommands.push(start.args.command);
      }
      // Pi's native read tool is the evidence. Prompt paths and unexecuted tool calls do not count.
      if (!e.isError && start?.toolName === "read" && e.toolName === "read" && typeof start.args?.path === "string") reads.add(start.args.path);
    }
  }
  const error = ["error", "aborted"].includes(stopReason) ? errors.at(-1) :
    !settled || stopReason !== "stop" || pending.size ? "Incomplete Pi transcript" : null;
  return { text, usage: messages && !missingUsage && settled ? usage : null, tools, commands, successfulCommands, errors, stopReason, error,
    skillRead: (name: string) => [...reads].some(path => path.endsWith(`.agents/skills/${name}/SKILL.md`)) };
}

export async function assertion(a: Assert, output: string, ctx: any, parsed?: ReturnType<typeof parsePi>, wallMs?: number) {
  if (a.type === "javascript" && a.value?.startsWith("file://")) {
    const mod = await import(join(ROOT, a.value.slice(7)));
    return await (mod.default ?? mod)(output, ctx);
  }
  if (a.type === "skill-used" && typeof a.value === "string") {
    const pass = parsed?.skillRead(a.value) ?? false;
    return { pass, reason: pass ? "successful read executed" : "no successful native SKILL.md read" };
  }
  if (a.type === "skill-unused" && typeof a.value === "string") {
    const pass = !(parsed?.skillRead(a.value) ?? false);
    return { pass, reason: pass ? "no SKILL.md read executed" : "unexpected native SKILL.md read" };
  }
  if (a.type === "latency" && typeof a.threshold === "number")
    return { pass: wallMs !== undefined && wallMs <= a.threshold, reason: wallMs === undefined ? "latency unknown" : `${wallMs}ms <= ${a.threshold}ms` };
  return { pass: false, reason: `unsupported assertion: ${a.type}` };
}

async function runPi(workdir: string, model: string, effort: string, prompt: string, attempt: string, row: any) {
  const agentDir = mkdtempSync(join(tmpdir(), "pi-agent-"));
  try {
    const managed = JSON.parse(readFileSync(resolve(ROOT, "../../pi/settings.json"), "utf8"));
    const settings = { defaultTools: managed.defaultTools, codemode: managed.codemode };
    save(join(agentDir, "settings.json"), settings);
    save(join(agentDir, "mcp.json"), { mcpServers: {} });
    const cred = join(process.env.HOME ?? "", ".pi/agent/auth.json");
    if (existsSync(cred)) symlinkSync(cred, join(agentDir, "auth.json"));
    const cmd = ["pi-agent", "--mode", "json", "-p", "--no-session", "--offline", "--no-approve",
      "--no-extensions", "--no-prompt-templates", "--no-themes", "--no-skills",
      "--extension", "builtin:codemode", "--extension", "builtin:mcp",
      "--provider", "openai-codex", "--model", model, "--thinking", effort, "--skill", join(workdir, ".agents/skills"), prompt];
    row.pi = { version: sh(workdir, ["pi-agent", "--version"]).trim(), command: cmd, settings, mcp: { mcpServers: {} },
      settingsSource: "isolated agent directory; managed codemode setting only; no live MCPs or project settings", timeoutMs: TIMEOUT_MS };
    save(join(attempt, "result.json"), row);
    const herdrBin = join(workdir, ".fixture/herdr-bin");
    const env = { ...process.env, PI_CODING_AGENT_DIR: agentDir, PATH: `${join(workdir, ".fixture/bin")}${existsSync(herdrBin) ? `:${herdrBin}` : ""}:${process.env.PATH ?? ""}`,
      GH_HOST: "example.invalid", GH_TOKEN: "fixture-no-real-token", GITHUB_TOKEN: "fixture-no-real-token" };
    const started = Date.now();
    const proc = Bun.spawn(cmd, { cwd: workdir, stdin: "ignore", stdout: "pipe", stderr: "pipe", env });
    const stream = async (source: ReadableStream<Uint8Array>, path: string) => {
      const reader = source.getReader();
      for (;;) { const { done, value } = await reader.read(); if (done) break; appendFileSync(path, value); }
    };
    const timer = setTimeout(() => proc.kill(9), TIMEOUT_MS);
    try {
      await Promise.all([stream(proc.stdout, join(attempt, "transcript.jsonl")), stream(proc.stderr, join(attempt, "stderr.txt"))]);
      row.exitCode = await proc.exited;
      row.wallMs = Date.now() - started;
    } finally { clearTimeout(timer); }
    return parsePi(readFileSync(join(attempt, "transcript.jsonl"), "utf8"));
  } finally { rmSync(agentDir, { recursive: true, force: true }); }
}

export async function main(args = process.argv.slice(2)) {
  if (!args.length || args.includes("--help")) {
    console.log("bun run.ts --list | --dry-run [--filter-pattern R] | --run [--filter-pattern R]");
    return 0;
  }
  const modes = args.filter(a => ["--list", "--dry-run", "--run"].includes(a));
  if (modes.length !== 1) throw new Error("Choose exactly one of --list, --dry-run, --run");
  let pattern: string | undefined;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--filter-pattern") {
      pattern = args[++i];
      if (pattern === undefined || pattern.startsWith("--")) throw new Error("--filter-pattern requires a regex");
    } else if (!["--list", "--dry-run", "--run"].includes(args[i])) throw new Error(`Unknown argument: ${args[i]}`);
  }
  const cfg: Config = JSON.parse(readFileSync(CONFIG, "utf8"));
  const { tests, providers } = select(cfg, pattern), paid = modes[0] === "--run";
  if (modes[0] === "--list") {
    for (const t of tests) for (const p of providers) console.log(`${p.label} :: ${t.description} [${t.vars.fixture}]`);
    return 0;
  }
  const results: any[] = [], batch = paid ? mkdtempSync(join(ROOT, "results-")) : null;
  if (batch) console.log(`Evidence: ${batch}`);
  for (const t of tests) for (const p of providers) {
    const attempt = mkdtempSync(join(batch ?? tmpdir(), `${p.label}-`));
    // Outside the checkout so Pi cannot inherit host repository instructions.
    const temporary = mkdtempSync(join(tmpdir(), "harness-fixture-")), workdir = join(temporary, "repo");
    const row: any = { provider: p.label, model: p.config.model, thinking: p.config.model_reasoning_effort ?? "medium",
      test: t.description, status: "started", executionWorkingDir: workdir, usage: null, assertions: [] };
    writeFileSync(join(attempt, "prompt.txt"), t.vars.request);
    writeFileSync(join(attempt, "transcript.jsonl"), ""); writeFileSync(join(attempt, "stderr.txt"), "");
    save(join(attempt, "result.json"), row);
    try {
      cpSync(join(ROOT, t.vars.fixture), workdir, { recursive: true, filter: path => !path.includes("/.agents/") });
      const fixtureSrc = join(ROOT, t.vars.fixture);
      const readList = (name: string) => existsSync(join(fixtureSrc, name))
        ? readFileSync(join(fixtureSrc, name), "utf8").split("\n").map(s => s.trim()).filter(Boolean) : null;
      const onlySkills = readList(".skills") ?? (existsSync(join(fixtureSrc, ".portable")) ? ["harness-boostrap"] : DEFAULT_SKILLS);
      const extraSkills = readList(".extra-skills") ?? [];
      const skills = [...onlySkills, ...extraSkills];
      row.inputHashes = { ...sourceHashes(ROOT, t.vars.fixture), ...materialize(workdir, resolve(ROOT, "../.."), { prepend: !existsSync(join(fixtureSrc, ".portable")), skills }) };
      mkdirSync(join(workdir, ".fixture", "bin"), { recursive: true });
      cpSync(join(ROOT, "gh.ts"), join(workdir, ".fixture/bin/gh"));
      chmodSync(join(workdir, ".fixture/bin/gh"), 0o755);
      if (existsSync(join(workdir, ".fixture/herdr-bin/herdr"))) chmodSync(join(workdir, ".fixture/herdr-bin/herdr"), 0o755);
      for (const cmd of [["init", "-q", "-b", "main"], ["config", "user.name", "Harness probe"],
        ["config", "user.email", "probe@example.invalid"], ["config", "core.hooksPath", "/dev/null"],
        ["config", "commit.gpgsign", "false"], ["add", "-A"], ["commit", "-qm", "seed"]]) sh(workdir, ["git", ...cmd]);
      const hashFile = (f: string) => createHash("sha256").update(readFileSync(join(workdir, f))).digest("hex");
      // Bench seeds the branch note after the seed commit, untracked and ignored.
      // Fold it out of the seed commit so check-ignore and status oracles behave the same.
      const agentFiles = existsSync(join(workdir, ".agent"))
        ? sh(workdir, ["git", "ls-files", ".agent"]).split("\n").filter(Boolean) : [];
      const seedNotes = Object.fromEntries(agentFiles.map(f => [f, hashFile(f)]));
      if (agentFiles.length) {
        sh(workdir, ["git", "rm", "-q", "--cached", "--", ...agentFiles]);
        sh(workdir, ["git", "commit", "-qm", "seed", "--amend", "--no-edit"]);
      }
      for (const cmd of [["init", "--bare", join(attempt, "origin.git")], ["remote", "add", "origin", join(attempt, "origin.git")],
        ["push", "-u", "origin", "main"]]) sh(workdir, ["git", ...cmd]);
      row.seedHead = sh(workdir, ["git", "rev-parse", "HEAD"]).trim();
      row.seedBranch = sh(workdir, ["git", "branch", "--show-current"]).trim();
      row.seedBranches = sh(workdir, ["git", "for-each-ref", "--format=%(refname)", "refs/heads"]).trim();
      if (existsSync(join(workdir, ".agent"))) {
        const exclude = sh(workdir, ["git", "rev-parse", "--git-path", "info/exclude"]).trim();
        appendFileSync(exclude.startsWith("/") ? exclude : join(workdir, exclude), "\n/.agent/\n");
      }
      row.seedFiles = Object.fromEntries(sh(workdir, ["git", "ls-files"]).split("\n").filter(Boolean).map(f =>
        [f, hashFile(f)]));
      Object.assign(row.seedFiles, seedNotes);
      save(join(attempt, "result.json"), row);
      const parsed = paid ? await runPi(workdir, row.model, row.thinking, t.vars.request, attempt, row) : undefined;
      row.output = parsed?.text ?? ""; row.usage = parsed?.usage ?? null; row.tools = parsed?.tools ?? []; row.commands = parsed?.commands ?? [];
      row.successfulCommands = parsed?.successfulCommands ?? [];
      row.providerErrors = parsed?.errors ?? [];
      if (paid && (row.exitCode !== 0 || parsed?.error)) throw new Error(parsed?.error || `pi exit ${row.exitCode}`);
      const ctx = { providerResponse: { metadata: { workingDir: workdir, seedHead: row.seedHead,
        seedBranch: row.seedBranch, seedBranches: row.seedBranches, seedFiles: row.seedFiles, commands: row.commands, successfulCommands: row.successfulCommands,
        workspaceDiff: sh(workdir, ["git", "diff", "HEAD"]) } } };
      for (const a of [...(cfg.defaultTest?.assert ?? []), ...t.assert])
        row.assertions.push({ ...a, ...await assertion(a, row.output, ctx, parsed, row.wallMs) });
      row.status = paid ? row.assertions.every((a: any) => a.pass) ? "pass" : "fail" : "dry";
    } catch (error) {
      row.status = "error"; row.error = String(error);
      appendFileSync(join(attempt, "stderr.txt"), `${error}\n`);
    } finally {
      if (batch && existsSync(workdir)) cpSync(workdir, join(attempt, "repo"), { recursive: true });
      save(join(attempt, "result.json"), row);
      rmSync(temporary, { recursive: true, force: true });
      if (!batch) rmSync(attempt, { recursive: true, force: true });
    }
    results.push(row);
    console.log(`${row.status.toUpperCase()} ${p.label} :: ${t.description}${row.error ? ` ${row.error}` : ""}`);
    for (const a of row.assertions) console.log(`   [${a.pass ? "x" : " "}] ${a.type}${a.value ? ":" + a.value : ""} ${a.reason ?? ""}`);
    if (batch) save(join(batch, "results.json"), results);
  }
  console.log(`\n${results.filter(r => r.status === "pass").length}/${results.length} passed (${results.filter(r => r.status === "dry").length} dry)`);
  return results.some(r => ["fail", "error"].includes(r.status)) ? 1 : 0;
}

if (import.meta.main) main().then(code => { process.exitCode = code; }).catch(error => { console.error(String(error)); process.exitCode = 1; });
