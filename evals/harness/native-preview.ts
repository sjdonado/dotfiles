import { createHash, randomUUID } from "node:crypto";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, realpathSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { materialize } from "./inputs";
import { registeredLaunch, checkedReadiness } from "./checks/native-preview";

// Opt-in native smoke, not the Pi runner: one model attempt per invocation.
const args = process.argv.slice(2), run = args.includes("--run");
const model = args.find((x) => x.startsWith("--model="))?.slice(8) ?? "gpt-6.1-sol";
if (args.some((x) => !["--run", "--dry-run", `--model=${model}`].includes(x)) ||
    args.includes("--dry-run") === run || !["gpt-6.1-sol", "gpt-6-luna"].includes(model))
  throw new Error("Usage: bun evals/harness/native-preview.ts (--dry-run|--run) [--model=gpt-6.1-sol|gpt-6-luna]");
const root = resolve(import.meta.dir, "../.."), temporary = process.env.TMPDIR;
if (!temporary || !existsSync(temporary)) throw new Error("An existing approved TMPDIR is required");
const fixture = realpathSync(mkdtempSync(join(temporary, "native-preview-")));
const evidence = join(import.meta.dir, `results-native-preview-${Date.now()}-${model}`);
mkdirSync(evidence);
const save = (name: string, value: unknown) => writeFileSync(join(evidence, name), JSON.stringify(value, null, 2) + "\n");
async function command(argv: string[], cwd = fixture) {
  const child = Bun.spawn(argv, { cwd, env: { ...process.env, PWD: cwd }, stdin: "ignore", stdout: "pipe", stderr: "pipe" });
  const timer = setTimeout(() => child.kill(), 15000);
  try {
    const [stdout, stderr, code] = await Promise.all([new Response(child.stdout).text(), new Response(child.stderr).text(), child.exited]);
    if (code) throw new Error(`${argv.slice(0, 4).join(" ")} failed (${code}): ${stderr}`);
    return stdout;
  } finally { clearTimeout(timer); }
}
const api = async (method: string, path: string, data?: unknown) => {
  const text = await command(["opencode", "api", method, path, ...(data ? ["--data", JSON.stringify(data)] : [])]);
  return text.trim() ? JSON.parse(text) : undefined;
};
const version = (await command(["opencode", "--version"])).trim();
if (version !== "opencode v2.0.26") throw new Error(`Expected OpenCode 2.0.26, got ${version}`);
// Read configuration only in memory; retain names/removal directives, never provider credentials.
const servers: Record<string, unknown> = {}, plugins: string[] = [];
const roots = new Set([join(homedir(), ".config/opencode"), join(homedir(), ".claude"), join(homedir(), ".agents")]);
for (let dir = fixture; ; dir = dirname(dir)) {
  roots.add(dir); roots.add(join(dir, ".opencode"));
  if (dirname(dir) === dir) break;
}
for (const dir of roots) {
  if (existsSync(join(dir, "opencode.jsonc"))) throw new Error("JSONC isolation needs inspection; smoke supports installed JSON config only");
  const path = join(dir, "opencode.json");
  if (existsSync(path)) {
    const config = JSON.parse(readFileSync(path, "utf8"));
    for (const name of Object.keys(config.mcp?.servers ?? {})) servers[name] = { type: "local", command: ["false"], disabled: true };
    for (const entry of config.plugins ?? []) {
      const target = typeof entry === "string" ? entry : entry.package;
      if (!target.startsWith("-")) plugins.push(`-${target.startsWith(".") ? resolve(dir, target) : target}`);
    }
  }
  for (const name of ["plugin", "plugins"]) {
    const path = join(dir, name);
    if (existsSync(path)) for (const entry of readdirSync(path)) plugins.push(`-${join(path, entry)}`);
  }
}
writeFileSync(join(fixture, "opencode.json"), JSON.stringify({ $schema: "https://opencode.ai/config.json", mcp: { servers }, plugins, warming: false }));
const listener = Bun.listen({ hostname: "127.0.0.1", port: 0, socket: { data() {} } });
const port = listener.port; listener.stop();
const marker = `native-preview-${randomUUID()}`, url = `http://127.0.0.1:${port}/`;
writeFileSync(join(fixture, "preview.py"), `from http.server import BaseHTTPRequestHandler, HTTPServer\nclass Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        body = ${JSON.stringify(marker)}.encode()\n        self.send_response(200)\n        self.end_headers()\n        self.wfile.write(body)\nHTTPServer(('127.0.0.1', ${port}), Handler).serve_forever()\n`);
writeFileSync(join(fixture, "AGENTS.md"), `# Disposable preview project\nThe standard-library Python preview is preview.py. Its ready URL is ${url}; the response must be ${marker}. Native shell inspection is available through opencode api get /api/shell. The API returns {location, data}; data contains id, cwd, status, command, and metadata.sessionID. Do not publish this disposable project.\n`);
const hashes = materialize(fixture, root);
hashes["evals/harness/inputs.ts"] = createHash("sha256").update(readFileSync(join(import.meta.dir, "inputs.ts"))).digest("hex");
hashes["evals/harness/checks/native-preview.ts"] = createHash("sha256").update(readFileSync(join(import.meta.dir, "checks/native-preview.ts"))).digest("hex");
await command(["git", "init", "-q"]);
cpSync(join(fixture, "AGENTS.md"), join(evidence, "AGENTS.md"));
cpSync(join(fixture, ".agents"), join(evidence, ".agents"), { recursive: true });
cpSync(join(fixture, "opencode.json"), join(evidence, "opencode.json"));
cpSync(join(fixture, "preview.py"), join(evidence, "preview.py"));
cpSync(join(import.meta.dir, "checks/native-preview.ts"), join(evidence, "native-preview-check.ts"));
const prompt = "Start the existing Python preview server so I can try it. Check that it is ready, give me its URL, and leave it running for my feedback.";
writeFileSync(join(evidence, "prompt.txt"), prompt);
const sessionID = `ses_nativepreview${randomUUID().replaceAll("-", "")}`;
const argv = ["opencode", "run", "--format", "json", "--auto", "--session", sessionID, "--model", `openai/${model}#medium`];
save("inputs.json", { version, argv, stdin: "prompt.txt", fixture, sessionID, model, variant: "medium", hashes,
  scriptHash: createHash("sha256").update(readFileSync(import.meta.path)).digest("hex"), timeoutMs: 300000,
  assertions: ["completed server shell input.background === true", "no shell detachment", "model checked registration and HTTP readiness", "owned shell still running after client returns", "HTTP fixture marker after client returns"] });
if (!run) {
  save("result.json", { status: "dry-run", behavioralAcceptance: "unverified", usage: "unknown" });
  console.log(`Seeded ${fixture}; declared assertions in ${evidence}`);
} else {
  const location = `?location[directory]=${encodeURIComponent(fixture)}`;
  const list = async () => (await api("get", `/api/shell${location}`)).data.filter((x: any) => x.cwd === fixture && x.metadata?.sessionID === sessionID);
  const baseline = new Set((await list()).map((x: any) => x.id));
  const result: Record<string, any> = { status: "failed", usage: "unknown" };
  let timedOut = false;
  try {
    const child = Bun.spawn(argv, { cwd: fixture, env: { ...process.env, PWD: fixture }, stdin: Bun.file(join(evidence, "prompt.txt")),
      stdout: Bun.file(join(evidence, "transcript.jsonl")), stderr: Bun.file(join(evidence, "stderr.txt")) });
    const timer = setTimeout(() => { timedOut = true; child.kill("SIGINT"); }, 300000);
    const hardStop = setTimeout(() => child.kill(), 305000);
    try { result.exitCode = await child.exited; } finally { clearTimeout(timer); clearTimeout(hardStop); }
    result.timedOut = timedOut;
    result.shells = await list(); // Filter before retaining anything from the shared service.
    result.http = await fetch(url, { signal: AbortSignal.timeout(5000) }).then(async (r) => ({ status: r.status, body: await r.text() })).catch(() => null);
    const events = readFileSync(join(evidence, "transcript.jsonl"), "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
    const tools = events.filter((x) => x.sessionID === sessionID && x.type === "tool_use").map((x) => x.part);
    const handoff = events.filter((x) => x.sessionID === sessionID && x.type === "text" && x.part.text?.trim()).at(-1);
    const beforeHandoff = tools.filter((x) => handoff && x.state.time?.end <= handoff.timestamp);
    const shells = tools.filter((x) => x.tool === "shell"), launches = shells.filter((x) => /(?:python3?|python)\b.*preview\.py/.test(x.state.input.command));
    result.assertions = {
      clientReturned: !timedOut && result.exitCode === 0 && !events.some((x) => x.type === "error"),
      finalResponse: events.some((x) => x.type === "text" && x.part.text?.trim() && launches.some((t) => x.timestamp >= t.state.time?.end)),
      background: launches.some((x) => x.state.status === "completed" && x.state.input.background === true),
      noDetachment: shells.every((x) => !/\b(nohup|disown|setsid)\b|(^|[^&<>])&(?![&>])/.test(x.state.input.command)),
      modelRegistration: launches.some((x) => beforeHandoff.includes(x) && registeredLaunch(x)),
      modelReadiness: beforeHandoff.some((x) => checkedReadiness(x, url, marker)),
      running: result.shells.some((x: any) => x.status === "running" && launches.some((t) => t.state.status === "completed" && t.state.input.background === true && t.state.metadata?.metadata?.shellID === x.id)),
      ready: result.http?.status === 200 && result.http?.body === marker,
    };
    result.usage = events.filter((x) => x.type === "step_finish").map((x) => ({ cost: x.part.cost ?? "unknown", tokens: x.part.tokens ?? "unknown" }));
    if (!result.usage.length) result.usage = "unknown";
    result.status = Object.values(result.assertions).every(Boolean) ? "passed" : "failed";
  } catch (error) { result.error = String(error); }
  finally {
    save("pre-cleanup.json", result);
    try {
      if (timedOut) await api("post", `/api/session/${sessionID}/interrupt`, {});
      const owned = (await list()).filter((x: any) => !baseline.has(x.id));
      result.cleanedShellIDs = [];
      for (const shell of owned) { await api("delete", `/api/shell/${shell.id}${location}`); result.cleanedShellIDs.push(shell.id); }
      result.cleanupVerified = (await list()).every((x: any) => baseline.has(x.id));
      if (!result.cleanupVerified) result.status = "failed";
    } catch (error) { result.cleanupError = String(error); result.status = "failed"; }
    save("result.json", result);
  }
  console.log(`${result.status}: ${evidence}`);
  if (result.status !== "passed") process.exitCode = 1;
}
