// Re-grade saved runs with the current oracles, from each run's saved answer,
// fixture-log.json and tool call log. No model, no fixture server.
//
//   bun run parity/regrade.ts --batch DIR --server chrome-devtools|safari|browser
//
// Each run's result.json records a fixture fingerprint. A scenario in FIXTURE_CHANGED
// is re-graded only when the run's fingerprint matches the current fixture and prompt.
// A run with a fingerprint is stale when it differs; a run without one is stale only for ids
// in FIXTURE_CHANGED. Stale runs print "needs re-run", because the saved answer came from a different page or prompt. A toolCall scenario with no saved toolCallLog also needs a re-run.

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fixtureFingerprint } from "./fixtures.ts";
import { check, scenarios } from "./scenarios.ts";

/** Scenarios whose fixture changed after runs without a fingerprint were saved. Runs with a matching fingerprint are re-graded; add an id here only for a change that predates fingerprints. */
const FIXTURE_CHANGED = new Set(["memory-leak", "slow-resource", "event-listener", "lcp-element", "geolocation", "failed-request", "console-errors"]);

const arg = (n: string) => (process.argv.includes(n) ? process.argv[process.argv.indexOf(n) + 1] : undefined);
const batch = arg("--batch");
const server = arg("--server");
if (!batch || !server) {
  console.error("usage: bun run parity/regrade.ts --batch DIR --server chrome-devtools|safari|browser");
  process.exit(2);
}
const root = join(batch, server);
if (!existsSync(root)) throw new Error(`no runs at ${root}`);

const verdict = (b: boolean) => (b ? "PASS" : "FAIL");
let oldPass = 0, newPass = 0, rerun = 0, changed = 0, graded = 0;
console.log(`${"scenario".padEnd(20)} ${"old".padEnd(5)} ${"new".padEnd(10)} note`);
for (const s of scenarios) {
  const dir = join(root, s.id);
  const resultPath = join(dir, "result.json");
  if (!existsSync(resultPath)) {
    console.log(`${s.id.padEnd(20)} ${"-".padEnd(5)} ${"-".padEnd(10)} no saved run`);
    continue;
  }
  const r = JSON.parse(readFileSync(resultPath, "utf8"));
  const log = existsSync(join(dir, "fixture-log.json")) ? JSON.parse(readFileSync(join(dir, "fixture-log.json"), "utf8")) : [];
  graded++;
  if (r.pass) oldPass++;
  const stale = r.fixtureFingerprint ? r.fixtureFingerprint !== fixtureFingerprint(s.id, s.prompt) : FIXTURE_CHANGED.has(s.id);
  const noCalls = !!s.toolCall && !Array.isArray(r.toolCallLog);
  if (stale || noCalls) {
    rerun++;
    console.log(`${s.id.padEnd(20)} ${verdict(r.pass).padEnd(5)} ${"needs re-run".padEnd(10)} ${stale ? "fixture changed since this run" : "no saved toolCallLog"}`);
    continue;
  }
  const oracles = check(s, r.answer ?? "", log, r.toolCallLog ?? [], server);
  const pass = r.status === "completed" && oracles.every((o) => o.pass);
  if (pass) newPass++;
  if (pass !== !!r.pass) changed++;
  const why = [
    r.status !== "completed" ? `status=${r.status}` : "",
    ...oracles.filter((o) => !o.pass).map((o) => `${o.kind}:${o.name}`),
  ].filter(Boolean).join(", ");
  console.log(`${s.id.padEnd(20)} ${verdict(r.pass).padEnd(5)} ${verdict(pass).padEnd(10)} ${pass !== !!r.pass ? "CHANGED " : ""}${why}`);
}
console.log(`\n${server} @ ${batch}: ${graded} runs, old ${oldPass} pass, new ${newPass} pass, ${rerun} need re-run, ${changed} verdicts changed`);
