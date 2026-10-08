import { expect, test } from "bun:test";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { assertion, main, parsePi, select, sh } from "./run";
import { sourceHashes } from "./inputs";

const transcript = (...events: unknown[]) => events.map(e => JSON.stringify(e)).join("\n");
const message = (stopReason = "stop", usage?: Record<string, number>) =>
  ({ type: "message_end", message: { role: "assistant", content: [{ type: "text", text: "final" }], stopReason, usage } });
const settled = { type: "agent_settled" };
const cfg = { providers: [{ id: "openai:codex-sdk", label: "luna", config: { model: "gpt-6-luna" } }],
  tests: [{ description: "one", vars: { fixture: "fixtures/bounded", request: "request" }, assert: [] }] };

test("failed git setup throws with diagnostics", () => {
  expect(() => sh(import.meta.dir, ["git", "definitely-not-a-git-operation"])).toThrow("git definitely-not-a-git-operation");
});
test("selection rejects unknown providers and empty matches", () => {
  expect(() => select(cfg, "missing")).toThrow("No scenarios selected");
  expect(() => select({ ...cfg, providers: [] })).toThrow("unsupported providers");
  expect(() => select({ ...cfg, providers: [{ ...cfg.providers[0], id: "unknown" }] })).toThrow("unsupported providers");
  expect(select(cfg).tests).toHaveLength(1);
});
test("CLI rejects missing filters, unknown flags and conflicting modes before calls", async () => {
  await expect(main(["--run", "--filter-pattern"])).rejects.toThrow("requires a regex");
  await expect(main(["--run", "--typo"])).rejects.toThrow("Unknown argument");
  await expect(main(["--dry-run", "--run"])).rejects.toThrow("exactly one");
  await expect(main(["--run", "--filter-pattern", "matches-no-scenario"])).rejects.toThrow("No scenarios selected");
});
test("zero-exit Pi errors and aborts cannot pass; recovered transient errors stay visible", () => {
  for (const stop of ["error", "aborted"]) expect(parsePi(transcript(message(stop), settled)).error).toBe(stop);
  const recovered = parsePi(transcript(message("error"), message("stop", { input: 3, output: 2 }), settled));
  expect(recovered.error).toBeNull();
  expect(recovered.errors).toEqual(["error"]);
  expect(recovered.usage).toBeNull();
});
test("missing and partial usage stay unknown; known zeros remain valid", () => {
  expect(parsePi(transcript(message(), settled)).usage).toBeNull();
  expect(parsePi(transcript(message("toolUse", { input: 2 }), message(), settled)).usage).toBeNull();
  expect(parsePi(transcript(message("toolUse", { input: 2 }), message("stop", { input: 3, output: 1 }), settled)).usage).toEqual({ input: 5, output: 1 });
  expect(parsePi(transcript(message("stop", { input: 0, output: 0 }), settled)).usage).toEqual({ input: 0, output: 0 });
});
test("prompt mentions, planned calls and failed reads are not executed skill reads", () => {
  const path = ".agents/skills/proto/SKILL.md";
  const start = { type: "tool_execution_start", toolCallId: "read-1", toolName: "read", args: { path } };
  const end = { type: "tool_execution_end", toolCallId: "read-1", toolName: "read", isError: false };
  const mention = { type: "message_end", message: { role: "user", content: [{ type: "text", text: path }] } };
  expect(parsePi(transcript(mention, message(), settled)).skillRead("proto")).toBe(false);
  expect(parsePi(transcript(start, message(), settled)).skillRead("proto")).toBe(false);
  expect(parsePi(transcript(start, { ...end, isError: true }, message(), settled)).skillRead("proto")).toBe(false);
  expect(parsePi(transcript(start, end, message(), settled)).skillRead("proto")).toBe(true);
});
test("malformed and incomplete transcripts fail rather than imply success", () => {
  expect(() => parsePi("not json")).toThrow();
  expect(parsePi("").error).toBe("Incomplete Pi transcript");
  expect(parsePi(transcript(message())).error).toBe("Incomplete Pi transcript");
  expect(parsePi(transcript(message("toolUse"), settled)).error).toBe("Incomplete Pi transcript");
});
test("only successful completed bash calls provide validation evidence", () => {
  const start = { type: 'tool_execution_start', toolCallId: 'bash-1', toolName: 'bash', args: { command: 'python3 check.py' } };
  const end = { type: 'tool_execution_end', toolCallId: 'bash-1', toolName: 'bash', isError: false };
  expect(parsePi(transcript(start, message(), settled)).successfulCommands).toEqual([]);
  expect(parsePi(transcript(start, { ...end, isError: true }, message(), settled)).successfulCommands).toEqual([]);
  expect(parsePi(transcript(start, end, message(), settled)).successfulCommands).toEqual(['python3 check.py']);
  expect(parsePi(transcript(start, { ...end, isError: true }, message(), settled)).commands).toEqual(['python3 check.py']);
});
test("unsupported assertions fail and default latency checks are measured", async () => {
  expect((await assertion({ type: "invented" }, "", {})).pass).toBe(false);
  expect((await assertion({ type: "javascript", value: "return true" }, "", {})).pass).toBe(false);
  expect((await assertion({ type: "latency", threshold: 10 }, "", {}, undefined, 11)).pass).toBe(false);
  expect((await assertion({ type: "latency", threshold: 10 }, "", {}, undefined, 10)).pass).toBe(true);
  expect((await assertion({ type: "latency", threshold: 10 }, "", {})).pass).toBe(false);
});
test("provenance hashes cover runner, JSON config, checks and exact fixture bytes", () => {
  const hashes = sourceHashes(import.meta.dir, "./fixtures/bounded");
  for (const path of ["run.ts", "inputs.ts", "gh.ts", "scenarios.json", "checks/state.js", "fixtures/bounded/label.py", "fixtures/bounded/.fixture/pr-history.json"]) {
    expect(hashes[`evals/harness/${path}`]).toBe(createHash("sha256").update(readFileSync(`${import.meta.dir}/${path}`)).digest("hex"));
  }
  expect(Object.keys(hashes).some(path => path.includes("/.agents/"))).toBe(false);
  expect(hashes["pi/settings.json"]).toBe(createHash("sha256").update(readFileSync(`${import.meta.dir}/../../pi/settings.json`)).digest("hex"));
});
