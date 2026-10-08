import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(import.meta.dir, "../.."), body = (path: string) => readFileSync(resolve(root, path), "utf8");
const json = (path: string) => JSON.parse(body(path));

test("native code mode is enabled without replacing native file tools", () => {
  expect(Bun.TOML.parse(body("mise.toml")).env.OPENCODE_EXPERIMENTAL_CODE_MODE).toBe("true");
  expect(body("fish/conf.d/opencode-codemode.fish")).toContain("set -gx OPENCODE_EXPERIMENTAL_CODE_MODE true");
  expect(json("pi/settings.json").defaultTools).toEqual(["+codemode"]);
  expect(json("pi/settings.json").codemode).toEqual({ mode: "on" });
});

test("Pi's code-mode MCP definitions match OpenCode's developer servers", () => {
  const opencode = json("opencode/opencode.json").mcp, pi = json("pi/mcp.json").mcpServers;
  expect(Object.keys(pi).sort()).toEqual(Object.keys(opencode).sort());
  for (const [name, server] of Object.entries(opencode) as [string, any][]) {
    expect(server.type).toBe("local");
    expect(pi[name].command).toBe(server.command[0]);
    expect(pi[name].args).toEqual(server.command.slice(1).map((arg: string) => arg.replaceAll("{env:HOME}/", "~/")));
    expect(pi[name].enabled ?? true).toBe(server.enabled);
    expect(pi[name].exposure).toBe("codemode");
  }
});

test("both paid eval paths explicitly load only native code mode and MCP", () => {
  for (const path of ["evals/harness/run.ts", "bench/measure"]) {
    expect(body(path)).toContain('"--no-extensions"');
    expect(body(path)).toContain('"builtin:codemode"');
    expect(body(path)).toContain('"builtin:mcp"');
    expect(body(path)).not.toContain('"--tools"');
    expect(body(path)).toContain("defaultTools");
    expect(body(path)).toContain('"--no-approve"');
  }
});
