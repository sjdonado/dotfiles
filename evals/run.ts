// Runs scenarios/*.yaml end to end against real Pi sessions. Bun, no packages. Only --run is paid.
import { appendFileSync, chmodSync, cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { createHash, randomUUID } from "node:crypto";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";

const ROOT = import.meta.dir, REPO = resolve(ROOT, "..");
const TURN_TIMEOUT_MS = 600_000;
const EXPECT_KEYS = ["skills", "notSkills", "ran", "notRan", "branch", "committed", "pushed", "clean", "check", "files", "pr", "reply"];

type Expect = {
  skills?: string[]; notSkills?: string[]; ran?: string[]; notRan?: string[]; branch?: string;
  committed?: boolean; pushed?: boolean; clean?: boolean; check?: string[];
  files?: Record<string, string | false>; pr?: Record<string, string[]> | false; reply?: string[];
};
type Scenario = {
  description: string; skills: string[]; core?: boolean; files: Record<string, string>; setup?: string[];
  turns: { prompt: string; setup?: string[]; expect: Expect }[];
};
type Model = { label: string; model: string; thinking: string };

const save = (path: string, value: unknown) => writeFileSync(path, JSON.stringify(value, null, 2) + "\n");
const re = (source: string) => new RegExp(source, "i");

function sh(dir: string, cmd: string[], env: Record<string, string | undefined> = process.env) {
  const p = Bun.spawnSync(cmd, { cwd: dir, env, stdout: "pipe", stderr: "pipe" });
  return { ok: p.exitCode === 0, out: p.stdout.toString().trim(), err: p.stderr.toString().trim() };
}
function must(dir: string, cmd: string[]) {
  const r = sh(dir, cmd);
  if (!r.ok) throw new Error(`${cmd.join(" ")}: ${r.err}`);
  return r.out;
}

function load(name: string): Scenario {
  const s = Bun.YAML.parse(readFileSync(join(ROOT, "scenarios", name), "utf8")) as any;
  if (typeof s.description !== "string" || !Array.isArray(s.skills) || !s.files || !Array.isArray(s.turns) || !s.turns.length)
    throw new Error(`${name}: needs description, skills, files, turns`);
  const missing = s.skills.filter((k: string) => !existsSync(join(REPO, "agents/skills", k, "SKILL.md")));
  if (missing.length) throw new Error(`${name}: unknown skills ${missing.join(", ")}`);
  for (const [i, t] of s.turns.entries()) {
    if (typeof t.prompt !== "string") throw new Error(`${name}: turn ${i + 1} has no prompt`);
    const unknown = Object.keys(t.expect ?? {}).filter(k => !EXPECT_KEYS.includes(k));
    if (unknown.length) throw new Error(`${name}: turn ${i + 1} has unknown expectations ${unknown.join(", ")}`);
  }
  return s;
}

// The repository under test: scenario files, then the live harness instructions and skills on top.
function seed(workdir: string, attempt: string, scenario: Scenario) {
  for (const [path, body] of Object.entries(scenario.files)) {
    mkdirSync(dirname(join(workdir, path)), { recursive: true });
    writeFileSync(join(workdir, path), body);
  }
  const project = existsSync(join(workdir, "AGENTS.md")) ? "\n" + readFileSync(join(workdir, "AGENTS.md"), "utf8") : "";
  writeFileSync(join(workdir, "AGENTS.md"), readFileSync(join(REPO, "agents/AGENTS.md"), "utf8") + project);
  cpSync(join(REPO, "agents/skills"), join(workdir, ".agents/skills"), { recursive: true });
  mkdirSync(join(workdir, ".fixture/bin"), { recursive: true });
  cpSync(join(ROOT, "gh.ts"), join(workdir, ".fixture/bin/gh"));
  chmodSync(join(workdir, ".fixture/bin/gh"), 0o755);
  for (const cmd of [["init", "-q", "-b", "main"], ["config", "user.name", "Eval"], ["config", "user.email", "eval@example.invalid"],
    ["config", "core.hooksPath", "/dev/null"], ["config", "commit.gpgsign", "false"]]) must(workdir, ["git", ...cmd]);
  // .fixture/ is forge state; a scenario that seeds .agent/ notes starts with them already ignored.
  const local = Object.keys(scenario.files).some(p => p.startsWith(".agent/")) ? "\n/.fixture/\n/.agent/\n" : "\n/.fixture/\n";
  appendFileSync(join(workdir, must(workdir, ["git", "rev-parse", "--git-path", "info/exclude"])), local);
  must(workdir, ["git", "add", "-A"]); must(workdir, ["git", "commit", "-qm", "seed"]);
  must(workdir, ["git", "init", "-q", "--bare", join(attempt, "origin.git")]);
  must(workdir, ["git", "remote", "add", "origin", join(attempt, "origin.git")]);
  must(workdir, ["git", "push", "-q", "-u", "origin", "main"]);
  return must(workdir, ["git", "rev-parse", "HEAD"]);
}

// Scenario and turn setup: shell commands that shape state the seed cannot (a pushed task branch, a merged PR).
function setup(workdir: string, cmds: string[] | undefined, env: Record<string, string | undefined>) {
  for (const cmd of cmds ?? []) {
    const r = sh(workdir, ["bash", "-c", cmd], env);
    if (!r.ok) throw new Error(`setup ${cmd}: ${r.err || r.out}`);
  }
}

function environment(workdir: string, extra: Record<string, string> = {}) {
  const env: Record<string, string | undefined> = { ...process.env, ...extra, PATH: `${join(workdir, ".fixture/bin")}:${process.env.PATH ?? ""}`,
    GH_HOST: "example.invalid", GH_TOKEN: "eval-no-real-token", GITHUB_TOKEN: "eval-no-real-token" };
  delete env.HERDR_ENV; // Sessions run outside herdr; never advertise a live workspace.
  return env;
}

function parse(jsonl: string) {
  let text = "", settled = false, stopReason = "";
  const usage: Record<string, number> = {}, commands: { command: string; ok: boolean }[] = [], reads: string[] = [], pending = new Map<string, any>();
  for (const line of jsonl.split("\n").filter(l => l.trim())) {
    let e: any;
    try { e = JSON.parse(line); } catch { continue; } // A turn killed at its timeout can end mid-line; the turn then reads as incomplete.
    if (e.type === "agent_settled") settled = true;
    if (e.type === "message_end" && e.message?.role === "assistant") {
      text = (e.message.content ?? []).filter((c: any) => c.type === "text").map((c: any) => c.text).join("") || text;
      stopReason = e.message.stopReason;
      for (const [k, v] of Object.entries(e.message.usage ?? {})) if (typeof v === "number") usage[k] = (usage[k] ?? 0) + v;
    } else if (e.type === "tool_execution_start") pending.set(e.toolCallId, e);
    else if (e.type === "tool_execution_end") {
      const start = pending.get(e.toolCallId);
      pending.delete(e.toolCallId);
      if (start?.toolName === "bash" && typeof start.args?.command === "string") commands.push({ command: start.args.command, ok: !e.isError });
      if (start?.toolName === "read" && !e.isError && typeof start.args?.path === "string") reads.push(start.args.path);
    }
  }
  const error = ["error", "aborted"].includes(stopReason) ? stopReason : !settled || stopReason !== "stop" || pending.size ? "incomplete transcript" : null;
  return { text, usage, commands, reads, error };
}

// Every expectation is data; this is the only place that interprets it.
function evaluate(expect: Expect, workdir: string, env: Record<string, string | undefined>, turn: ReturnType<typeof parse>, headBefore: string) {
  const results: { name: string; pass: boolean; detail?: string }[] = [];
  const add = (name: string, pass: boolean, detail?: string) => results.push({ name, pass, detail });
  const skillRead = (name: string) => turn.reads.some(p => p.endsWith(`.agents/skills/${name}/SKILL.md`));
  for (const s of expect.skills ?? []) add(`skill ${s}`, skillRead(s));
  for (const s of expect.notSkills ?? []) add(`no skill ${s}`, !skillRead(s));
  for (const r of expect.ran ?? []) add(`ran /${r}/`, turn.commands.some(c => c.ok && re(r).test(c.command)));
  for (const r of expect.notRan ?? []) {
    const hit = turn.commands.find(c => re(r).test(c.command));
    add(`never ran /${r}/`, !hit, hit?.command);
  }
  const branch = sh(workdir, ["git", "branch", "--show-current"]).out, head = sh(workdir, ["git", "rev-parse", "HEAD"]).out;
  if (expect.branch !== undefined) add(`branch /${expect.branch}/`, re(expect.branch).test(branch), branch);
  if (expect.committed !== undefined) add(`committed ${expect.committed}`, (head !== headBefore) === expect.committed);
  if (expect.pushed !== undefined) {
    const remote = sh(workdir, ["git", "ls-remote", "origin", `refs/heads/${branch}`]).out.split(/\s/)[0];
    add(`pushed ${expect.pushed}`, (!!branch && remote === head) === expect.pushed, `${branch} ${remote || "absent"}`);
  }
  if (expect.clean !== undefined) {
    const status = sh(workdir, ["git", "status", "--porcelain"]).out;
    add(`clean ${expect.clean}`, !status === expect.clean, status);
  }
  for (const cmd of expect.check ?? []) {
    const r = sh(workdir, ["bash", "-c", cmd], env);
    add(`check ${cmd}`, r.ok, (r.err || r.out).slice(0, 300));
  }
  for (const [path, pattern] of Object.entries(expect.files ?? {})) {
    const file = join(workdir, path), exists = existsSync(file);
    add(pattern === false ? `no file ${path}` : `file ${path} /${pattern}/`,
      pattern === false ? !exists : exists && re(pattern).test(readFileSync(file, "utf8")));
  }
  if (expect.pr !== undefined) {
    const prFile = join(workdir, ".fixture/pr.json"), pr = existsSync(prFile) ? JSON.parse(readFileSync(prFile, "utf8")) : null;
    if (expect.pr === false) add("no PR", pr === null, pr?.url);
    else for (const [field, patterns] of Object.entries(expect.pr)) for (const p of patterns)
      add(`PR ${field} /${p}/`, !!pr && re(p).test(String(pr[field] ?? "")));
  }
  for (const r of expect.reply ?? []) add(`reply /${r}/`, re(r).test(turn.text));
  return results;
}

async function pi(workdir: string, attempt: string, model: Model, sessionId: string, prompt: string, n: number, env: Record<string, string | undefined>) {
  const agentDir = mkdtempSync(join(tmpdir(), "pi-agent-"));
  try {
    const managed = JSON.parse(readFileSync(join(REPO, "pi/settings.json"), "utf8"));
    save(join(agentDir, "settings.json"), { defaultTools: managed.defaultTools, codemode: managed.codemode });
    save(join(agentDir, "mcp.json"), { mcpServers: {} });
    const cred = join(process.env.HOME ?? "", ".pi/agent/auth.json");
    if (existsSync(cred)) symlinkSync(cred, join(agentDir, "auth.json"));
    const cmd = ["pi-agent", "--mode", "json", "-p", "--session-dir", join(attempt, "session"), "--session-id", sessionId,
      "--offline", "--no-approve", "--no-extensions", "--no-prompt-templates", "--no-themes", "--no-skills",
      "--extension", "builtin:codemode", "--extension", "builtin:mcp",
      "--provider", "openai", "--model", model.model, "--thinking", model.thinking, "--skill", join(workdir, ".agents/skills"), prompt];
    const transcript = join(attempt, `turn-${n}.jsonl`);
    const proc = Bun.spawn(cmd, { cwd: workdir, stdin: "ignore", stdout: Bun.file(transcript), stderr: Bun.file(join(attempt, `turn-${n}.stderr`)),
      env: { ...env, PI_CODING_AGENT_DIR: agentDir } });
    const timer = setTimeout(() => proc.kill(9), TURN_TIMEOUT_MS);
    const started = Date.now(), exitCode = await proc.exited;
    clearTimeout(timer);
    return { exitCode, wallMs: Date.now() - started, command: cmd, ...parse(readFileSync(transcript, "utf8")) };
  } finally { rmSync(agentDir, { recursive: true, force: true }); }
}

// What a result was measured against: the harness inputs and the eval itself.
function inputsHash() {
  const hash = createHash("sha256");
  const walk = (dir: string) => {
    for (const entry of readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const path = join(dir, entry.name);
      if (entry.name.startsWith("results-")) continue;
      if (entry.isDirectory()) walk(path);
      else hash.update(path.slice(REPO.length)).update(readFileSync(path));
    }
  };
  for (const dir of ["agents", "evals"]) walk(join(REPO, dir));
  hash.update(readFileSync(join(REPO, "pi/settings.json")));
  return hash.digest("hex");
}

async function main(args = process.argv.slice(2)) {
  const mode = args.find(a => ["--list", "--dry-run", "--run"].includes(a));
  if (!mode) { console.log("bun run.ts --list | --dry-run | --run [--all | --skill NAME | --filter R] [--model LABEL]"); return 0; }
  const option = (name: string) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : undefined; };
  const filter = option("--filter"), skill = option("--skill"), only = option("--model");
  // A paid run with no selector runs only the core scenarios; --list and --dry-run are free and cover everything.
  const coreOnly = mode === "--run" && !args.includes("--all") && !skill && !filter;
  const scenarios = readdirSync(join(ROOT, "scenarios")).filter(f => f.endsWith(".yaml") && (!filter || re(filter).test(f)))
    .map(n => [n, load(n)] as const).filter(([, s]) => (!skill || s.skills.includes(skill)) && (!coreOnly || s.core));
  const models: Model[] = JSON.parse(readFileSync(join(ROOT, "models.json"), "utf8")).filter((m: Model) => !only || m.label === only);
  if (!scenarios.length || !models.length) throw new Error("No scenarios or models selected");
  if (mode === "--list") {
    for (const [n, s] of scenarios) for (const m of models)
      console.log(`${m.label} :: ${n} [${s.core ? "core, " : ""}${s.skills.join(", ")}] (${s.turns.length} turns) ${s.description}`);
    return 0;
  }
  const paid = mode === "--run", batch = mkdtempSync(join(paid ? ROOT : tmpdir(), "results-")), rows: any[] = [];
  const inputs = { hash: inputsHash(), commit: must(REPO, ["git", "rev-parse", "HEAD"]), dirty: !!must(REPO, ["git", "status", "--porcelain", "--", "agents", "evals"]),
    pi: paid ? must(REPO, ["pi-agent", "--version"]) : null };
  if (paid) console.log(`Evidence: ${batch}`);
  for (const [name, scenario] of scenarios) for (const model of models) {
    const attempt = join(batch, `${name.replace(/\.yaml$/, "")}-${model.label}`), workdir = mkdtempSync(join(tmpdir(), "eval-repo-"));
    mkdirSync(attempt, { recursive: true });
    const row: any = { scenario: name, ...model, inputs, status: "started", turns: [] };
    try {
      const seedHead = seed(workdir, attempt, scenario), env = environment(workdir, { SEED: seedHead }), sessionId = randomUUID();
      setup(workdir, scenario.setup, env);
      for (const [i, t] of scenario.turns.entries()) {
        setup(workdir, t.setup, env);
        const headBefore = must(workdir, ["git", "rev-parse", "HEAD"]);
        const turn = paid ? await pi(workdir, attempt, model, sessionId, t.prompt, i + 1, env)
          : { text: "", usage: {}, commands: [], reads: [], error: null, exitCode: 0, wallMs: 0, command: [] };
        const expectations = evaluate(t.expect, workdir, env, turn, headBefore);
        const pass = !turn.error && turn.exitCode === 0 && expectations.every(e => e.pass);
        row.turns.push({ prompt: t.prompt, pass, error: turn.error, exitCode: turn.exitCode, wallMs: turn.wallMs, usage: turn.usage, reply: turn.text, expectations });
        console.log(`${pass ? "PASS" : paid ? "FAIL" : "DRY "} ${model.label} :: ${name} turn ${i + 1}${turn.error ? ` (${turn.error})` : ""}`);
        for (const e of expectations) console.log(`   [${e.pass ? "x" : " "}] ${e.name}${!e.pass && e.detail ? `  -> ${e.detail}` : ""}`);
        if (paid && !pass) break; // Later turns build on this one.
      }
      row.status = !paid ? "dry" : row.turns.length === scenario.turns.length && row.turns.every((t: any) => t.pass) ? "pass" : "fail";
    } catch (error) {
      row.status = "error"; row.error = String(error);
      console.log(`ERROR ${model.label} :: ${name} ${error}`);
    } finally {
      if (paid) cpSync(workdir, join(attempt, "repo"), { recursive: true });
      rmSync(workdir, { recursive: true, force: true });
      save(join(attempt, "result.json"), row);
      rows.push(row);
    }
  }
  if (!paid) rmSync(batch, { recursive: true, force: true });
  else save(join(batch, "results.json"), rows);
  console.log(paid ? `\n${rows.filter(r => r.status === "pass").length}/${rows.length} passed`
    : `\n${rows.filter(r => r.status === "dry").length}/${rows.length} seeded; expectations were checked against the seed, so failures are expected`);
  return paid && rows.some(r => r.status !== "pass") ? 1 : rows.some(r => r.status === "error") ? 1 : 0;
}

if (import.meta.main) main().then(code => { process.exitCode = code; }).catch(error => { console.error(String(error)); process.exitCode = 1; });
