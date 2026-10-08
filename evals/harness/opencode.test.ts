import { expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

test("OpenCode's native execute adapter chains real MCP calls without a model", () => {
  const binary = Bun.which("opencode");
  if (!binary) throw new Error("OpenCode unavailable; native adapter is unverified");
  const evidence = mkdtempSync(join(import.meta.dir, "results-opencode-"));
  const workdir = mkdtempSync(join(tmpdir(), "opencode-codemode-"));
  const server = join(import.meta.dir, "fixtures/codemode/mcp-server.mjs");
  const save = (name: string, value: unknown) => writeFileSync(join(evidence, name), JSON.stringify(value, null, 2) + "\n");
  const code = 'const first = await tools.fixture.echo({value: "seed"}); return await tools.fixture.echo({value: first.output});';
  const config = { model: "fixture/offline", autoupdate: false, plugin: [], enabled_providers: ["fixture"],
    provider: { fixture: { npm: "@ai-sdk/openai-compatible", models: { offline: { name: "Offline fixture" } },
      options: { baseURL: "http://127.0.0.1:1/v1", apiKey: "fixture-not-a-credential" } } },
    mcp: { fixture: { type: "local", command: [process.execPath, server, join(evidence, "mcp-calls.jsonl")], enabled: true } } };
  for (const path of ["home", "config", "data", "state", "cache"]) mkdirSync(join(workdir, path));
  writeFileSync(join(workdir, "opencode.json"), JSON.stringify(config));
  writeFileSync(join(evidence, "prompt.txt"), code + "\n");
  save("config.json", config);
  copyFileSync(server, join(evidence, "mcp-server.mjs"));
  const hashes: Record<string, string> = {};
  for (const path of [server, import.meta.path]) hashes[path] = createHash("sha256").update(readFileSync(path)).digest("hex");
  save("hashes.json", hashes);
  const env = { HOME: join(workdir, "home"), PATH: [dirname(binary), dirname(process.execPath), "/usr/bin", "/bin"].join(":"),
    XDG_CONFIG_HOME: join(workdir, "config"), XDG_DATA_HOME: join(workdir, "data"), XDG_STATE_HOME: join(workdir, "state"), XDG_CACHE_HOME: join(workdir, "cache"),
    OPENCODE_DISABLE_MODELS_FETCH: "true", OPENCODE_DISABLE_DEFAULT_PLUGINS: "true", OPENCODE_DISABLE_CLAUDE_CODE: "true", OPENCODE_DISABLE_EXTERNAL_SKILLS: "true" };
  const command = [binary, "--pure", "debug", "agent", "build", "--tool", "execute", "--params", JSON.stringify({ code })];
  save("command.json", command);
  save("settings.json", { ...env, OPENCODE_EXPERIMENTAL_CODE_MODE: "true" });
  const started = Date.now();
  let passed = false;
  try {
    const version = Bun.spawnSync([binary, "--version"], { env, stdout: "pipe", stderr: "pipe", timeout: 10_000 });
    save("version.json", { version: version.stdout.toString().trim(), exitCode: version.exitCode });
    expect(version.exitCode).toBe(0);
    expect(version.stdout.toString().trim()).toBe("1.18.34");
    const disabled = Bun.spawnSync(command, { cwd: workdir, env: { ...env, OPENCODE_EXPERIMENTAL_CODE_MODE: "false" }, stdout: "pipe", stderr: "pipe", timeout: 30_000 });
    writeFileSync(join(evidence, "disabled.stdout.txt"), disabled.stdout);
    writeFileSync(join(evidence, "disabled.stderr.txt"), disabled.stderr);
    expect(disabled.exitCode).not.toBe(0);
    expect(disabled.stderr.toString()).toContain("Tool execute not found");
    const result = Bun.spawnSync(command, { cwd: workdir, env: { ...env, OPENCODE_EXPERIMENTAL_CODE_MODE: "true" }, stdout: "pipe", stderr: "pipe", timeout: 30_000 });
    writeFileSync(join(evidence, "stdout.json"), result.stdout);
    writeFileSync(join(evidence, "stderr.txt"), result.stderr);
    expect(result.exitCode).toBe(0);
    const parsed = JSON.parse(result.stdout.toString());
    expect(parsed.tool).toBe("execute");
    expect(parsed.result.metadata.toolCalls.map((call: any) => [call.tool, call.status])).toEqual([["fixture.echo", "completed"], ["fixture.echo", "completed"]]);
    expect(JSON.parse(parsed.result.output)).toEqual({ value: "mcp-1:seed", output: "mcp-2:mcp-1:seed" });
    expect(readFileSync(join(evidence, "mcp-calls.jsonl"), "utf8").trim().split("\n").map(line => JSON.parse(line))).toEqual([
      { value: "seed", output: "mcp-1:seed" }, { value: "mcp-1:seed", output: "mcp-2:mcp-1:seed" }]);
    passed = true;
  } finally {
    save("result.json", { passed, wallMs: Date.now() - started, scope: "native debug tool execution, not model-facing tool selection or permission prompts" });
    rmSync(workdir, { recursive: true, force: true });
  }
}, 45_000);
