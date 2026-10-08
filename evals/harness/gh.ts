#!/usr/bin/env bun
// Local forge substitute; unsupported operations fail and are logged as refused.
// Bun port of bench/fixture_gh.py. Log format is identical: {"args": [...], "served": bool}.
import { appendFileSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

function git(...args: string[]): string {
  const p = Bun.spawnSync(["git", ...args], { stdout: "pipe", stderr: "ignore" });
  return p.stdout.toString().trim();
}

function fail(msg: string): never {
  // Throw instead of process.exit: exiting skips finally, Python sys.exit raises.
  console.error(msg);
  throw new Refuse(msg);
}
class Refuse extends Error {}

const root = join(git("rev-parse", "--show-toplevel"), ".fixture");
const args = process.argv.slice(2);
let served = false;

function log() {
  appendFileSync(join(root, "operations.jsonl"), JSON.stringify({ args, served }) + "\n");
}

function option(name: string, fallback = ""): string {
  const i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
}

async function stdinText(): Promise<string> {
  return await Bun.stdin.text();
}

const readJson = (name: string) => JSON.parse(readFileSync(join(root, name), "utf8"));
const writeJson = (name: string, v: unknown) => writeFileSync(join(root, name), JSON.stringify(v));

try {
  const prPath = join(root, "pr.json");
  const histPath = join(root, "pr-history.json");
  const pr = existsSync(prPath) ? JSON.parse(readFileSync(prPath, "utf8")) : null;
  const history = existsSync(histPath) ? JSON.parse(readFileSync(histPath, "utf8")) : [];
  const pair = args.slice(0, 2).join(" ");
  if (args.includes("--help") || args.includes("-h")) {
    // A usage probe must never mutate the forge.
    console.log("fixture gh: usage of " + args.slice(0, 2).join(" "));
    served = true;
  } else if (pair === "pr view" || pair === "pr list") {
    if (args[1] === "view" && pr === null) fail("No pull request found");
    const value = args[1] === "list" ? [...(pr ? [pr] : []), ...history] : pr;
    if (args.includes("--jq")) {
      const q = option("--jq");
      if (pr === null || !q.startsWith(".") || !(q.slice(1) in pr)) fail("Unsupported fixture jq expression");
      const field = pr[q.slice(1)];
      console.log(typeof field === "string" ? field : JSON.stringify(field));
    } else if (args.includes("--json") || args[1] === "list") {
      console.log(JSON.stringify(value));
    } else {
      console.log(`${pr.title} #${pr.number}\n${pr.state} · ${pr.headRefName} -> ${pr.baseRefName}\n${pr.url}`);
    }
    served = true;
  } else if (pair === "pr create") {
    const bodyFile = option("--body-file");
    const body = bodyFile ? ((bodyFile === "-" ? await stdinText() : readFileSync(bodyFile, "utf8"))) : option("--body");
    const created = { number: 8, state: "OPEN", mergedAt: null, title: option("--title"), body,
      url: "https://example.invalid/pull/8",
      headRefName: (option("--head") || option("-H")).split(":").pop() || git("branch", "--show-current"),
      baseRefName: option("--base", "main"), statusCheckRollup: [],
      mergeable: "MERGEABLE", mergeStateStatus: "CLEAN", isDraft: args.includes("--draft") };
    const remoteHeadAtCreation = git("ls-remote", "origin", `refs/heads/${created.headRefName}`).split(/\s/)[0];
    Object.assign(created, { remoteHeadAtCreation });
    writeJson("pr.json", created);
    console.log(created.url);
    served = true;
  } else if (pair === "pr checks") {
    console.log(args.includes("--json") ? "[]" : "No required checks");
    served = true;
  } else if (pair === "pr edit") {
    if (pr === null) fail("No pull request found");
    for (const [opt, field] of [["--title", "title"], ["--body", "body"], ["--body-file", "body"]] as const) {
      if (args.includes(opt)) {
        const v = option(opt);
        pr[field] = opt === "--body-file" ? (v === "-" ? await stdinText() : readFileSync(v, "utf8")) : v;
        served = true;
      }
    }
    if (!served) fail("Fixture pr edit supports only --title, --body, --body-file");
    writeJson("pr.json", pr);
    console.log(pr.url);
  } else if (pair === "issue view") {
    const issue = readJson("issue.json");
    if (args.includes("--json")) {
      console.log(JSON.stringify(issue));
    } else {
      const comments = (issue.comments ?? []).map((r: any) => r.body).join("\n\n");
      console.log(`${issue.title} #${issue.number}\n${issue.state}\n\n${issue.body}\n\n${comments}`);
    }
    served = true;
  } else if (pair === "issue comment") {
    const issue = readJson("issue.json");
    const bodyFile = option("--body-file");
    const body = bodyFile ? (bodyFile === "-" ? await stdinText() : readFileSync(bodyFile, "utf8")) : option("--body");
    if (!body) fail("Fixture issue comment requires --body or --body-file");
    issue.comments = [...(issue.comments ?? []), { author: { login: "agent" }, body }];
    writeJson("issue.json", issue);
    served = true;
    console.log(issue.url + "#issuecomment-2");
  } else if (pair === "issue close") {
    const issue = readJson("issue.json");
    issue.state = "CLOSED";
    writeJson("issue.json", issue);
    served = true;
    console.log("Closed issue #" + issue.number);
  } else {
    fail("Unsupported fixture operation; no external service was called");
  }
} catch (e) {
  if (!(e instanceof Refuse)) throw e;
  process.exitCode = 1;
} finally {
  log();
}
