import { afterEach, expect, test } from "bun:test";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { continuationSource, seedRepository, select, sh, fixtureEnvironment } from "./run";

const temporary: string[] = [];
const sandbox = () => {
  const dir = mkdtempSync(join(tmpdir(), "harness-run-test-"));
  temporary.push(dir);
  return dir;
};
afterEach(() => { for (const dir of temporary.splice(0)) rmSync(dir, { recursive: true, force: true }); });
const testCase = (fixture: string, continueFrom?: string) => ({ description: fixture,
  vars: { fixture, continueFrom, request: "test" }, assert: [] });
const providers = [{ id: "openai", label: "sol", config: { model: "gpt-6.1-sol" } }];

test("disposable fixture does not inherit a live Herdr workspace", () => {
  const before = process.env.HERDR_ENV;
  try {
    process.env.HERDR_ENV = "1";
    const env = fixtureEnvironment(sandbox());
    expect(env.HERDR_ENV).toBeUndefined();
    expect(env.GH_HOST).toBe("example.invalid");
    expect(process.env.HERDR_ENV).toBe("1");
  } finally {
    if (before === undefined) delete process.env.HERDR_ENV;
    else process.env.HERDR_ENV = before;
  }
});

test("select includes continuation dependencies before a filtered fresh round", () => {
  const first = testCase("first"), second = testCase("second", "first");
  expect(select({ providers, tests: [second, first] }, "second").tests).toEqual([first, second]);
  expect(() => select({ providers, tests: [second] })).toThrow("requires one predecessor");
  expect(() => select({ providers, tests: [testCase("first", "second"), second] })).toThrow("Cyclic");
});

test("seeded feedback and phase notes match their declared branch", () => {
  const cfg = JSON.parse(readFileSync(join(import.meta.dir, "scenarios.json"), "utf8"));
  for (const test of cfg.tests.filter(test => /\/fixtures\/(feedback(?:-local-first|-approved-batch)?|phase-r3)$/.test(test.vars.fixture))) {
    expect(test.vars.branch).toBe("proto/handoff");
    expect(existsSync(join(import.meta.dir, test.vars.fixture, ".agent/proto%2Fhandoff.md"))).toBe(true);
  }
});

test("feedback starts on an existing PR branch with ignored, uncommitted notes", () => {
  const root = sandbox(), repo = join(root, "repo"), attempt = join(root, "attempt");
  mkdirSync(join(repo, ".agent"), { recursive: true });
  mkdirSync(attempt);
  writeFileSync(join(repo, "label.py"), "def label(text): return text\n");
  writeFileSync(join(repo, ".agent/proto%2Fhandoff.md"), "Saved requirements\n");
  const seed = seedRepository(repo, attempt, "proto/handoff");
  expect(seed.seedBranch).toBe("proto/handoff");
  expect(sh(repo, ["git", "show-ref", "--verify", "refs/heads/main"])).toContain(seed.seedHead);
  expect(sh(repo, ["git", "ls-files", ".agent"])).toBe("");
  expect(sh(repo, ["git", "check-ignore", ".agent/proto%2Fhandoff.md"]).trim()).toBe(".agent/proto%2Fhandoff.md");
  expect(sh(repo, ["git", "rev-parse", "origin/proto/handoff"]).trim()).toBe(seed.seedHead);
});

test("fresh continuation carries predecessor code, note, rationale and Git state", () => {
  const root = sandbox(), first = join(root, "first"), repo = join(first, "repo");
  mkdirSync(repo, { recursive: true });
  writeFileSync(join(repo, "label.py"), "def label(text): return text\n");
  const seed = seedRepository(repo, first);
  writeFileSync(join(repo, "label.py"), "def label(text): return ' '.join(text.split())\n");
  mkdirSync(join(repo, ".agent"));
  writeFileSync(join(repo, ".agent/main.md"), "Preserve Northstar branding. Deferred fallback: Untitled\n");
  writeFileSync(join(repo, "design.md"), "Keep partner casing\n");
  const previous = new Map([["sol:first", { attempt: first, status: "pass", inputHashes: {} }]]);
  const source = continuationSource(previous, "sol", "first", true);
  const second = join(root, "second"), nextRepo = join(second, "repo");
  mkdirSync(second);
  cpSync(join(source.attempt, "repo"), nextRepo, { recursive: true });
  const next = seedRepository(nextRepo, second, undefined, true);
  expect(next.seedHead).toBe(seed.seedHead);
  expect(next.seedBranch).toBe("main");
  expect(readFileSync(join(nextRepo, "label.py"), "utf8")).toContain("split()");
  expect(readFileSync(join(nextRepo, ".agent/main.md"), "utf8")).toContain("Untitled");
  expect(existsSync(join(nextRepo, "design.md"))).toBe(true);
  expect(sh(nextRepo, ["git", "diff", "HEAD"])).toContain("split()");
  expect(sh(nextRepo, ["git", "remote", "get-url", "origin"]).trim()).toBe(join(second, "origin.git"));
  expect(() => continuationSource(previous, "luna", "first", true)).toThrow("unavailable");
  previous.set("sol:first", { ...source, status: "fail" });
  expect(() => continuationSource(previous, "sol", "first", true)).toThrow("not accepted");
  expect(continuationSource(previous, "sol", "first", false)).toBe(previous.get("sol:first"));
});
