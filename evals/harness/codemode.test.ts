import { expect, test } from "bun:test";
import { createHash } from "node:crypto";
import {
  appendFileSync,
  cpSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { parsePi } from "./run";

const ROOT = import.meta.dir;
const FIXTURE = join(ROOT, "fixtures/codemode");
const timeoutMs = 30_000;

function sha256(path: string) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function installedPiPackage() {
  const pi = Bun.which("pi-agent");
  if (!pi) throw new Error("Pi CLI is unavailable; native code-mode fixture was not run");
  const upstream = Bun.spawnSync([pi, "--upstream-path"], { stdout: "pipe", stderr: "pipe" });
  if (upstream.exitCode !== 0) throw new Error("pi-agent could not locate its upstream executable");
  const resolved = realpathSync(upstream.stdout.toString().trim());
  const version = Bun.spawnSync([pi, "--version"], { stdout: "pipe", stderr: "pipe" });
  const output = version.stdout.toString().trim();
  if (version.exitCode !== 0 || output !== "1.0.2") throw new Error(`Expected Pi 1.0.2, found ${output || "no version"}`);
  let packageDir = "";
  for (let dir = dirname(resolved); ; dir = dirname(dir)) {
    if (existsSync(join(dir, "package.json"))) {
      try {
        const pkg = JSON.parse(readFileSync(join(dir, "package.json"), "utf8"));
        if (pkg.name === "@earendil-works/pi-coding-agent") { packageDir = dir; break; }
      } catch { /* Keep walking parent directories. */ }
    }
    if (dirname(dir) === dir) break;
  }
  if (!packageDir) packageDir = resolve(dirname(resolved), "../libexec/lib/node_modules/@earendil-works/pi-coding-agent");
  const aiModule = join(packageDir, "node_modules/@earendil-works/pi-ai/dist/index.js");
  if (!existsSync(aiModule)) throw new Error(`Pi 1.0.2 SDK modules are unavailable at ${packageDir}`);
  return { pi, resolved, packageDir, aiModule, version: output };
}

test("Pi native codemode runs nested read, bash, and chained MCP calls offline", async () => {
  const runtime = installedPiPackage();
  const evidence = mkdtempSync(join(ROOT, "results-codemode-"));
  cpSync(FIXTURE, join(evidence, "inputs"), { recursive: true });
  copyFileSync(import.meta.path, join(evidence, "inputs", "test-source.txt"));
  copyFileSync(join(ROOT, "../../pi/settings.json"), join(evidence, "inputs", "pi-settings.json"));
  const agentDir = join(evidence, "agent");
  const runRoot = mkdtempSync(join(tmpdir(), "pi-codemode-run-"));
  const workdir = join(runRoot, "workspace");
  mkdirSync(agentDir);
  mkdirSync(workdir);
  copyFileSync(join(FIXTURE, "fixture.txt"), join(workdir, "fixture.txt"));
  const providerLog = join(evidence, "provider-observed.jsonl");
  const mcpLog = join(evidence, "mcp-calls.jsonl");
  const transcriptPath = join(evidence, "transcript.jsonl");
  const stderrPath = join(evidence, "stderr.txt");
  const prompt = "Run the fixed offline codemode checks and return the final result.";
  writeFileSync(join(evidence, "prompt.txt"), `${prompt}\n`);
  writeFileSync(join(agentDir, "mcp.json"), `${JSON.stringify({ mcpServers: {
    fixture: {
      command: process.execPath,
      args: [join(FIXTURE, "mcp-server.mjs"), mcpLog],
      cwd: workdir,
      exposure: "codemode",
      timeout: 10,
    },
  } }, null, 2)}\n`);
  copyFileSync(join(agentDir, "mcp.json"), join(evidence, "mcp-settings.json"));
  const managedPiSettings = JSON.parse(readFileSync(join(ROOT, "../../pi/settings.json"), "utf8"));
  const isolatedSettings = { defaultTools: managedPiSettings.defaultTools, codemode: managedPiSettings.codemode };
  writeFileSync(join(agentDir, "settings.json"), `${JSON.stringify(isolatedSettings, null, 2)}\n`);
  copyFileSync(join(agentDir, "settings.json"), join(evidence, "agent-settings.json"));
  writeFileSync(transcriptPath, "");
  writeFileSync(stderrPath, "");
  writeFileSync(join(evidence, "settings.json"), `${JSON.stringify({
    piVersion: runtime.version,
    isolatedAgentDirectory: agentDir,
    projectSettings: "none; workspace is a fresh temporary directory",
    credentialSources: "disabled; isolated HOME and agent directory; no imported credentials",
    enabledExtensions: ["fixture provider", "builtin:codemode", "builtin:mcp"],
    modelUsage: "unknown; deterministic local streamSimple fixture, no actual model usage measured",
    defaultTools: isolatedSettings.defaultTools,
    codeMode: isolatedSettings.codemode,
  }, null, 2)}\n`);
  writeFileSync(join(evidence, "hashes.json"), `${JSON.stringify({
    "fixtures/codemode/provider.mjs": sha256(join(FIXTURE, "provider.mjs")),
    "fixtures/codemode/mcp-server.mjs": sha256(join(FIXTURE, "mcp-server.mjs")),
    "fixtures/codemode/fixture.txt": sha256(join(FIXTURE, "fixture.txt")),
    "codemode.test.ts": sha256(join(ROOT, "codemode.test.ts")),
    "pi/settings.json": sha256(join(ROOT, "../../pi/settings.json")),
  }, null, 2)}\n`);

  const cmd = [runtime.pi, "--mode", "json", "-p", "--no-session", "--offline", "--no-approve",
    "--no-prompt-templates", "--no-themes", "--no-skills",
    "--no-extensions", "-e", join(FIXTURE, "provider.mjs"), "-e", "builtin:codemode", "-e", "builtin:mcp",
    "--provider", "harness-fixture", "--model", "offline", prompt];
  writeFileSync(join(evidence, "command.json"), `${JSON.stringify(cmd, null, 2)}\n`);
  const safePath = [dirname(runtime.pi), dirname(process.execPath), "/usr/bin", "/bin"].join(":");
  const env = {
    HOME: agentDir,
    PATH: safePath,
    LANG: "C.UTF-8",
    PI_CODING_AGENT_DIR: agentDir,
    PI_FIXTURE_AI_MODULE: pathToFileURL(runtime.aiModule).href,
    PI_FIXTURE_PROVIDER_LOG: providerLog,
  };
  const startedAt = Date.now();
  writeFileSync(join(evidence, "result.json"), JSON.stringify({ status: "started", piVersion: runtime.version, usage: null }) + "\n");
  const proc = Bun.spawn(cmd, { cwd: workdir, env, stdin: "ignore", stdout: "pipe", stderr: "pipe" });
  const collect = async (source: ReadableStream<Uint8Array>, path: string) => {
    const reader = source.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) return;
      appendFileSync(path, value);
    }
  };
  const timer = setTimeout(() => proc.kill(9), timeoutMs);
  let exitCode: number;
  try {
    await Promise.all([collect(proc.stdout, transcriptPath), collect(proc.stderr, stderrPath)]);
    exitCode = await proc.exited;
  } finally {
    clearTimeout(timer);
  }
  cpSync(workdir, join(evidence, "workspace"), { recursive: true });
  rmSync(runRoot, { recursive: true, force: true });
  writeFileSync(join(evidence, "result.json"), `${JSON.stringify({
    piVersion: runtime.version,
    piBinary: runtime.resolved,
    piPackage: runtime.packageDir,
    exitCode,
    status: "fail",
    wallMs: Date.now() - startedAt,
    transcript: "transcript.jsonl",
    stderr: "stderr.txt",
    providerObserved: "provider-observed.jsonl",
    mcpCalls: "mcp-calls.jsonl",
  }, null, 2)}\n`);

  const lines = readFileSync(transcriptPath, "utf8").split("\n").filter(Boolean).map(line => JSON.parse(line));
  const execution = new Map<string, any>();
  for (const event of lines) {
    if (event.type === "tool_execution_start") execution.set(event.toolCallId, { start: event });
    if (event.type === "tool_execution_end") execution.get(event.toolCallId)!.end = event;
  }
  const calls = [...execution.values()];
  const providerCalls = readFileSync(providerLog, "utf8").split("\n").filter(Boolean).map(line => JSON.parse(line));
  const mcpCalls = readFileSync(mcpLog, "utf8").split("\n").filter(Boolean).map(line => JSON.parse(line));
  const nested = calls.filter(call => call.start.parentToolCallId);
  const codemode = calls.find(call => call.start.toolName === "codemode" && !call.start.parentToolCallId);
  const finalAssistant = [...lines].reverse().find(event => event.type === "message_end" && event.message?.role === "assistant");
  const summary = {
    exitCode,
    settled: lines.some(event => event.type === "agent_settled"),
    stopReason: finalAssistant?.message?.stopReason,
    toolNames: calls.map(call => call.start.toolName),
    nestedCalls: nested.map(call => ({ toolName: call.start.toolName, parentToolCallId: call.start.parentToolCallId,
      toolCallId: call.start.toolCallId, isError: call.end?.isError })),
    modelVisibleTools: providerCalls[0]?.toolNames,
    mcpCalls,
    evidence: evidence.replace(`${ROOT}/`, ""),
  };
  writeFileSync(join(evidence, "assertions.json"), `${JSON.stringify(summary, null, 2)}\n`);

  let status = "fail", error: string | undefined;
  try {
  expect(exitCode, `CLI failed. Evidence: ${evidence}; stderr: ${readFileSync(stderrPath, "utf8")}`).toBe(0);
  expect(summary.settled).toBe(true);
  expect(summary.stopReason).toBe("stop");
  expect(summary.toolNames).toContain("codemode");
  expect(codemode).toBeDefined();
  expect(nested.map(call => call.start.toolName)).toEqual(expect.arrayContaining(["read", "bash", "mcp__fixture__echo"]));
  expect(nested).toHaveLength(4);
  expect(nested.every(call => call.start.parentToolCallId === codemode.start.toolCallId && call.end && !call.end.isError)).toBe(true);
  expect(providerCalls).toHaveLength(2);
  expect(providerCalls[0].toolNames).toEqual(expect.arrayContaining(["read", "bash", "edit", "write", "codemode"]));
  expect(providerCalls[0].toolNames).not.toContain("mcp__fixture__echo");
  expect(mcpCalls).toEqual([
    { value: "seed", output: "mcp-1:seed" },
    { value: "mcp-1:seed", output: "mcp-2:mcp-1:seed" },
  ]);
  expect(readFileSync(join(evidence, "workspace", "bash-marker.txt"), "utf8")).toBe("bash-ok");
  expect(readFileSync(join(evidence, "workspace", "fixture.txt"), "utf8")).toBe("codemode-read-ok\n");
  const parsed = parsePi(readFileSync(transcriptPath, "utf8"));
  expect(parsed.error).toBeNull();
  expect(parsed.successfulCommands).toEqual(["printf bash-ok > bash-marker.txt"]);
  expect(parsed.tools.filter(name => name === "mcp__fixture__echo")).toHaveLength(2);
  status = "pass";
  } catch (failure) { error = String(failure); throw failure; }
  finally {
    writeFileSync(join(evidence, "result.json"), JSON.stringify({ status, error, piVersion: runtime.version,
      exitCode, wallMs: Date.now() - startedAt, usage: null, assertions: summary }) + "\n");
  }
}, 35_000);
