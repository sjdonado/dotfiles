// Offline tests for gh.ts. Free, no model calls: bun test gh.test.ts
import { expect, test } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const GH = join(import.meta.dir, "gh.ts");
const ISSUE = { number: 86, state: "OPEN", title: "4 vulnerable dependencies", body: "add undici", comments: [], url: "https://example.invalid/issues/86" };

function setup(files: Record<string, unknown> = {}) {
  const dir = mkdtempSync(join(tmpdir(), "gh-test-"));
  Bun.spawnSync(["git", "init", "-q", "-b", "main"], { cwd: dir });
  mkdirSync(join(dir, ".fixture"), { recursive: true });
  for (const [name, v] of Object.entries(files)) writeFileSync(join(dir, ".fixture", name), JSON.stringify(v));
  return dir;
}

function gh(dir: string, args: string[], stdin?: string) {
  const p = Bun.spawnSync(["bun", GH, ...args], { cwd: dir, stdin: stdin ? Buffer.from(stdin) : "ignore", stdout: "pipe", stderr: "pipe" });
  return { code: p.exitCode, out: p.stdout.toString().trim(), err: p.stderr.toString().trim() };
}

function ops(dir: string) {
  return readFileSync(join(dir, ".fixture", "operations.jsonl"), "utf8").trim().split("\n").map((l) => JSON.parse(l));
}

test("issue view, comment, close round trip", () => {
  const dir = setup({ "issue.json": ISSUE });
  const v = gh(dir, ["issue", "view", "--json"]);
  expect(v.code).toBe(0);
  expect(JSON.parse(v.out).number).toBe(86);
  const c = gh(dir, ["issue", "comment", "--body", "grounded reply"]);
  expect(c.code).toBe(0);
  const k = gh(dir, ["issue", "close"]);
  expect(k.code).toBe(0);
  expect(k.out).toBe("Closed issue #86");
  expect(JSON.parse(readFileSync(join(dir, ".fixture", "issue.json"), "utf8")).state).toBe("CLOSED");
  expect(ops(dir).every((o) => o.served)).toBe(true);
});

test("pr create, view, edit, checks", () => {
  const dir = setup({ "pr-history.json": [] });
  const none = gh(dir, ["pr", "view"]);
  expect(none.code).not.toBe(0);
  const c = gh(dir, ["pr", "create", "--title", "WIP: x", "--body", "why"]);
  expect(c.code).toBe(0);
  expect(c.out).toBe("https://example.invalid/pull/8");
  const pr = JSON.parse(readFileSync(join(dir, ".fixture", "pr.json"), "utf8"));
  expect(pr.mergeable).toBe("MERGEABLE");
  const e = gh(dir, ["pr", "edit", "--title", "x"]);
  expect(e.code).toBe(0);
  expect(ops(dir).at(-1)).toEqual({ args: ["pr", "edit", "--title", "x"], served: true });
  expect(existsSync(join(dir, ".fixture", "operations.jsonl"))).toBe(true);
});

test("help never mutates, unknown op refused", () => {
  const dir = setup({ "pr-history.json": [] });
  const h = gh(dir, ["pr", "create", "--help"]);
  expect(h.code).toBe(0);
  expect(existsSync(join(dir, ".fixture", "pr.json"))).toBe(false);
  const bad = gh(dir, ["pr", "merge"]);
  expect(bad.code).not.toBe(0);
  expect(ops(dir).at(-1)).toEqual({ args: ["pr", "merge"], served: false });
});
