// Prepare disposable repositories and check deterministic scenario outcomes. No agent runner.
import { chmodSync, cpSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

const ROOT = import.meta.dir;
const REPO = resolve(ROOT, "..");
type Expect = { branch?: string; committed?: boolean; pushed?: boolean; clean?: boolean; check?: string[]; files?: Record<string, string | false>; pr?: Record<string, string[]> | false };
type Scenario = { description: string; skills: string[]; files: Record<string, string>; setup?: string[]; turns: { prompt: string; setup?: string[]; expect: Expect }[] };
const re = (s: string) => new RegExp(s, "i");
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
  const path = name.endsWith(".yaml") ? name : `${name}.yaml`;
  const scenario = Bun.YAML.parse(readFileSync(join(ROOT, "scenarios", path), "utf8")) as Scenario;
  if (!scenario.description || !scenario.skills?.length || !scenario.files || !scenario.turns?.length) throw new Error(`${path}: needs description, skills, files and turns`);
  return scenario;
}
function environment(workdir: string) {
  return { ...process.env, PATH: `${join(workdir, ".fixture/bin")}:${process.env.PATH ?? ""}`, GH_HOST: "example.invalid", GH_TOKEN: "eval-no-real-token", GITHUB_TOKEN: "eval-no-real-token" };
}
function setup(workdir: string, commands: string[] | undefined, env: Record<string, string | undefined>) {
  for (const command of commands ?? []) {
    const r = sh(workdir, ["bash", "-c", command], env);
    if (!r.ok) throw new Error(`setup ${command}: ${r.err || r.out}`);
  }
}
function prepare(name: string, workdir: string) {
  const scenario = load(name);
  mkdirSync(workdir, { recursive: true });
  if (readdirSync(workdir).length) throw new Error(`refusing to seed nonempty directory: ${workdir}`);
  for (const [path, body] of Object.entries(scenario.files)) {
    mkdirSync(dirname(join(workdir, path)), { recursive: true });
    writeFileSync(join(workdir, path), body);
  }
  const project = existsSync(join(workdir, "AGENTS.md")) ? `\n${readFileSync(join(workdir, "AGENTS.md"), "utf8")}` : "";
  writeFileSync(join(workdir, "AGENTS.md"), `${readFileSync(join(REPO, "agents/AGENTS.md"), "utf8")}${project}`);
  cpSync(join(REPO, "agents/skills"), join(workdir, ".agents/skills"), { recursive: true });
  mkdirSync(join(workdir, ".fixture/bin"), { recursive: true });
  cpSync(join(ROOT, "gh.ts"), join(workdir, ".fixture/bin/gh"));
  chmodSync(join(workdir, ".fixture/bin/gh"), 0o755);
  for (const args of [["init", "-q", "-b", "main"], ["config", "user.name", "Eval"], ["config", "user.email", "eval@example.invalid"], ["config", "core.hooksPath", "/dev/null"], ["config", "commit.gpgsign", "false"]]) must(workdir, ["git", ...args]);
  const excludes = must(workdir, ["git", "rev-parse", "--git-path", "info/exclude"]);
  writeFileSync(join(workdir, excludes), `${readFileSync(join(workdir, excludes), "utf8")}\n/.fixture/\n/.agent/\n`);
  must(workdir, ["git", "add", "-A"]);
  must(workdir, ["git", "commit", "-qm", "seed"]);
  const origin = join(workdir, ".fixture/origin.git");
  must(workdir, ["git", "init", "-q", "--bare", origin]);
  must(workdir, ["git", "remote", "add", "origin", origin]);
  must(workdir, ["git", "push", "-q", "-u", "origin", "main"]);
  const seed = must(workdir, ["git", "rev-parse", "HEAD"]);
  setup(workdir, scenario.setup, { ...environment(workdir), SEED: seed });
  writeFileSync(join(workdir, ".fixture/seed"), `${seed}\n`);
  console.log(`Prepared ${name} at ${workdir}`);
  console.log(`Skills: ${scenario.skills.join(", ")}`);
  console.log(`Agent environment: PATH="${join(workdir, ".fixture/bin")}:$PATH" GH_HOST=example.invalid`);
  begin(name, workdir, 1);
}
function begin(name: string, workdir: string, turnIndex: number) {
  const scenario = load(name), turn = scenario.turns[turnIndex - 1];
  if (!turn) throw new Error(`turn must be 1..${scenario.turns.length}`);
  const baselinePath = join(workdir, `.fixture/turn-${turnIndex}-head`);
  if (existsSync(baselinePath)) throw new Error(`turn ${turnIndex} already began`);
  const env = { ...environment(workdir), SEED: readFileSync(join(workdir, ".fixture/seed"), "utf8").trim() };
  setup(workdir, turn.setup, env);
  writeFileSync(baselinePath, `${must(workdir, ["git", "rev-parse", "HEAD"])}\n`);
  console.log(`Turn ${turnIndex}:\n${turn.prompt}`);
}
function check(name: string, workdir: string, turnIndex: number) {
  const scenario = load(name), turn = scenario.turns[turnIndex - 1];
  if (!turn) throw new Error(`turn must be 1..${scenario.turns.length}`);
  const env = { ...environment(workdir), SEED: readFileSync(join(workdir, ".fixture/seed"), "utf8").trim() };
  const expect = turn.expect, results: { name: string; pass: boolean; detail?: string }[] = [];
  const add = (label: string, pass: boolean, detail?: string) => results.push({ name: label, pass, detail });
  const branch = sh(workdir, ["git", "branch", "--show-current"]).out;
  const head = sh(workdir, ["git", "rev-parse", "HEAD"]).out;
  if (expect.branch !== undefined) add(`branch /${expect.branch}/`, re(expect.branch).test(branch), branch);
  const baseline = readFileSync(join(workdir, `.fixture/turn-${turnIndex}-head`), "utf8").trim();
  if (expect.committed !== undefined) add(`committed ${expect.committed}`, (head !== baseline) === expect.committed);
  if (expect.pushed !== undefined) {
    const remote = sh(workdir, ["git", "ls-remote", "origin", `refs/heads/${branch}`]).out.split(/\s/)[0];
    add(`pushed ${expect.pushed}`, (!!branch && remote === head) === expect.pushed, `${branch} ${remote || "absent"}`);
  }
  if (expect.clean !== undefined) add(`clean ${expect.clean}`, !sh(workdir, ["git", "status", "--porcelain"]).out === expect.clean);
  for (const command of expect.check ?? []) {
    const r = sh(workdir, ["bash", "-c", command], env);
    add(`check ${command}`, r.ok, (r.err || r.out).slice(0, 300));
  }
  for (const [path, pattern] of Object.entries(expect.files ?? {})) {
    const file = join(workdir, path), exists = existsSync(file);
    add(pattern === false ? `no file ${path}` : `file ${path} /${pattern}/`, pattern === false ? !exists : exists && re(pattern).test(readFileSync(file, "utf8")));
  }
  if (expect.pr !== undefined) {
    const prFile = join(workdir, ".fixture/pr.json"), pr = existsSync(prFile) ? JSON.parse(readFileSync(prFile, "utf8")) : null;
    if (expect.pr === false) add("no PR", pr === null, pr?.url);
    else for (const [field, patterns] of Object.entries(expect.pr)) for (const pattern of patterns) add(`PR ${field} /${pattern}/`, !!pr && re(pattern).test(String(pr[field] ?? "")));
  }
  for (const result of results) console.log(`${result.pass ? "PASS" : "FAIL"} ${result.name}${result.detail ? `: ${result.detail}` : ""}`);
  console.log(`${results.filter(r => r.pass).length}/${results.length} deterministic checks passed`);
  return results.every(r => r.pass) ? 0 : 1;
}
async function main(args = process.argv.slice(2)) {
  const [command, ...rest] = args;
  if (command === "list") {
    for (const file of readdirSync(join(ROOT, "scenarios")).filter(f => f.endsWith(".yaml"))) {
      const s = load(file);
      console.log(`${file} :: ${s.skills.join(", ")} :: ${s.turns.length} turns :: ${s.description}`);
    }
    return 0;
  }
  if (command === "prepare" && rest.length === 2) { prepare(rest[0], resolve(rest[1])); return 0; }
  if (command === "check" && rest.length === 3) return check(rest[0], resolve(rest[1]), Number(rest[2]));
  if (command === "begin" && rest.length === 3) { begin(rest[0], resolve(rest[1]), Number(rest[2])); return 0; }
  console.log("bun evals/run.ts list | prepare <scenario> <directory> | begin <scenario> <directory> <turn> | check <scenario> <directory> <turn>");
  return 2;
}
if (import.meta.main) main().then(code => { process.exitCode = code; }).catch(error => { console.error(String(error)); process.exitCode = 1; });
