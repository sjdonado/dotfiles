#!/usr/bin/env bun
// git-bug MCP server.
//
// Why: `git bug termui` holds git-bug's own repository lock
// (.git/git-bug/lock), so every `git bug` CLI read fails with
// "already locked by the process pid N" while it is open. Reads in this
// server never call the git-bug CLI: they read refs/bugs/* and
// refs/identities/* straight from git plumbing, which git-bug's lock does
// not affect. Writes go through the real `git bug` CLI, non-interactively,
// because it is the only safe way to write git-bug's data; they check the
// lock first and refuse if it is held, rather than retrying or clearing it.
//
// git-bug data shapes (verified against git-bug v0.11.0 and a real repo):
// - refs/bugs/<id> and refs/identities/<id> are commit chains. Each bug
//   commit's tree has one blob named "ops" holding JSON: {"author":{"id":
//   "..."},"ops":[{"type":N,"timestamp":...,"nonce":"...", ...}, ...]}.
//   Every op in a commit shares that commit's author (OpBase.author is
//   unexported in git-bug and is never itself part of an op's JSON).
// - An operation's id is sha256(hex) of the *exact bytes* of its JSON
//   object as it sits in the "ops" array (git-bug computes op.Id() as
//   sha256(json.Marshal(op)), and Go's json.Marshal output for that op is
//   byte-identical whether marshaled alone or embedded in the array, since
//   there is no extra whitespace either way). A bug's own id is its create
//   operation's id, which is also the refs/bugs/<id> suffix. Verified: the
//   create-op blob for refs/bugs/95ffb53... hashes to exactly
//   95ffb53b4f121f5b23249145c08124ff3708e7dbba1d1b6dda07a0dd98921b75.
// - Op types: 1 create (title, message), 2 set title (title), 3 add
//   comment (message), 4 set status (status: 1 open, 2 closed), 5 label
//   change (added[], removed[]), 6 edit comment (target, message). "target"
//   is the id (per above) of the create op (editing the description) or an
//   add-comment op (editing that comment); an edit whose target is not
//   found is a no-op, matching git-bug's own EditCommentOperation.Apply.
// - refs/identities/<id> has one blob per commit named "version", holding
//   {"name":...,"email":...,...} directly (not wrapped in an ops array).
// - git-bug's own lock file is .git/git-bug/lock, containing just the
//   locking process's pid as decimal text, no newline (cache/repo_cache.go,
//   multi_repo_cache.go: `const lockfile = "lock"`).

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// ---------- process helpers ----------

interface RunResult {
  code: number | null;
  stdout: string;
  stderr: string;
}

function run(argv: string[], opts: { cwd?: string; input?: string } = {}): Promise<RunResult> {
  return new Promise((resolve, reject) => {
    const child = spawn(argv[0]!, argv.slice(1), { cwd: opts.cwd });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (d) => (stdout += d));
    child.stderr.on("data", (d) => (stderr += d));
    child.on("error", reject);
    child.on("close", (code) => resolve({ code, stdout, stderr }));
    if (opts.input !== undefined) child.stdin.write(opts.input);
    child.stdin.end();
  });
}

async function git(repo: string, args: string[]): Promise<string> {
  const r = await run(["git", "-C", repo, ...args]);
  if (r.code !== 0) throw new Error(`git ${args.join(" ")} failed: ${r.stderr.trim()}`);
  return r.stdout;
}

// Throws when the object is missing; callers let that fail the whole read.
async function catBlob(repo: string, hash: string): Promise<string> {
  return git(repo, ["cat-file", "-p", hash]);
}

function sha256hex(s: string): string {
  return createHash("sha256").update(s, "utf8").digest("hex");
}

// ---------- raw JSON substring extraction (for op-id hashing) ----------

// Finds the exact source substrings of each top-level element of the
// array that follows `"ops":[` in raw, preserving original byte-for-byte
// formatting (needed because op ids are hashes of that exact text, not of
// a re-serialized object).
function splitOpsArray(raw: string): string[] {
  const key = `"ops":[`;
  const keyIdx = raw.indexOf(key);
  if (keyIdx === -1) return [];
  let i = keyIdx + key.length;
  const out: string[] = [];
  while (i < raw.length && raw[i] !== "]") {
    if (raw[i] === ",") {
      i++;
      continue;
    }
    if (raw[i] !== "{") break;
    const start = i;
    let depth = 0;
    let inStr = false;
    let esc = false;
    for (; i < raw.length; i++) {
      const c = raw[i];
      if (inStr) {
        if (esc) esc = false;
        else if (c === "\\") esc = true;
        else if (c === '"') inStr = false;
      } else {
        if (c === '"') inStr = true;
        else if (c === "{") depth++;
        else if (c === "}") {
          depth--;
          if (depth === 0) {
            i++;
            break;
          }
        }
      }
    }
    out.push(raw.slice(start, i));
  }
  return out;
}

// ---------- identities ----------

interface Identity {
  id: string;
  name: string;
  email: string;
}

async function loadIdentities(repo: string): Promise<Map<string, Identity>> {
  const refsOut = await git(repo, ["for-each-ref", "--format=%(refname)", "refs/identities/"]);
  const refs = refsOut.split("\n").filter(Boolean);
  const identities = new Map<string, Identity>();
  for (const ref of refs) {
    const id = ref.split("/").pop()!;
    const commits = (await git(repo, ["rev-list", ref])).split("\n").filter(Boolean);
    // The newest commit (rev-list without --reverse gives newest-first)
    // holds the current name/email.
    const newest = commits[0];
    if (!newest) continue;
    const tree = await git(repo, ["ls-tree", newest]);
    const line = tree.split("\n").find((l) => l.endsWith("\tversion"));
    if (!line) continue;
    const blobHash = line.split(/\s+/)[2];
    if (!blobHash) continue;
    try {
      const data = JSON.parse(await catBlob(repo, blobHash));
      identities.set(id, { id, name: data.name ?? "", email: data.email ?? "" });
    } catch {
      // skip malformed identity data rather than fail the whole request
    }
  }
  return identities;
}

// ---------- bugs ----------

interface Comment {
  opId: string;
  authorId: string;
  timestamp: number;
  message: string;
  edited: boolean;
}

interface Bug {
  id: string;
  shortId: string;
  title: string;
  status: "open" | "closed";
  labels: Set<string>;
  authorId: string;
  createdAt: number;
  updatedAt: number;
  description: Comment;
  comments: Comment[];
}

async function listBugRefs(repo: string): Promise<string[]> {
  const out = await git(repo, ["for-each-ref", "--format=%(refname)", "refs/bugs/"]);
  return out.split("\n").filter(Boolean);
}

async function loadBug(repo: string, ref: string): Promise<Bug | null> {
  const id = ref.split("/").pop()!;
  const commits = (await git(repo, ["rev-list", "--reverse", ref])).split("\n").filter(Boolean);
  if (commits.length === 0) return null;

  let bug: Bug | null = null;
  const opIndex = new Map<string, { kind: "description" } | { kind: "comment"; index: number }>();

  for (const commit of commits) {
    const tree = await git(repo, ["ls-tree", commit]);
    const opsLine = tree.split("\n").find((l) => {
      const name = l.split(/\s+/)[3];
      return name && name.startsWith("ops");
    });
    if (!opsLine) continue;
    const blobHash = opsLine.split(/\s+/)[2];
    if (!blobHash) continue;
    const raw = await catBlob(repo, blobHash);

    let pack: { author?: { id?: string }; ops?: any[] };
    try {
      pack = JSON.parse(raw);
    } catch {
      continue;
    }
    const commitAuthorId = pack.author?.id ?? "";
    const opSubstrings = splitOpsArray(raw);
    const ops = pack.ops ?? [];

    for (let idx = 0; idx < ops.length; idx++) {
      const op = ops[idx];
      const substr = opSubstrings[idx];
      const opId = substr ? sha256hex(substr) : "";

      switch (op.type) {
        case 1: {
          bug = {
            id,
            shortId: id.slice(0, 7),
            title: op.title ?? "",
            status: "open",
            labels: new Set(),
            authorId: commitAuthorId,
            createdAt: op.timestamp,
            updatedAt: op.timestamp,
            description: {
              opId,
              authorId: commitAuthorId,
              timestamp: op.timestamp,
              message: op.message ?? "",
              edited: false,
            },
            comments: [],
          };
          opIndex.set(opId, { kind: "description" });
          break;
        }
        case 2: {
          if (bug) bug.title = op.title ?? bug.title;
          break;
        }
        case 3: {
          if (!bug) break;
          bug.comments.push({
            opId,
            authorId: commitAuthorId,
            timestamp: op.timestamp,
            message: op.message ?? "",
            edited: false,
          });
          opIndex.set(opId, { kind: "comment", index: bug.comments.length - 1 });
          break;
        }
        case 4: {
          if (bug) bug.status = op.status === 2 ? "closed" : "open";
          break;
        }
        case 5: {
          if (!bug) break;
          for (const l of op.added ?? []) bug.labels.add(l);
          for (const l of op.removed ?? []) bug.labels.delete(l);
          break;
        }
        case 6: {
          if (!bug) break;
          const target = opIndex.get(op.target);
          if (!target) break; // unresolved target: no-op, matches git-bug
          if (target.kind === "description") {
            bug.description.message = op.message ?? bug.description.message;
            bug.description.edited = true;
          } else {
            bug.comments[target.index]!.message = op.message ?? bug.comments[target.index]!.message;
            bug.comments[target.index]!.edited = true;
          }
          break;
        }
        default:
          break;
      }
      if (bug) bug.updatedAt = op.timestamp;
    }
  }

  return bug;
}

async function loadAllBugs(repo: string): Promise<Bug[]> {
  const refs = await listBugRefs(repo);
  const bugs: Bug[] = [];
  for (const ref of refs) {
    const bug = await loadBug(repo, ref);
    if (bug) bugs.push(bug);
  }
  return bugs;
}

function resolveBugByPrefix(bugs: Bug[], prefix: string): Bug {
  const matches = bugs.filter((b) => b.id.startsWith(prefix));
  if (matches.length === 0) throw new Error(`no bug matches id prefix "${prefix}"`);
  if (matches.length > 1) {
    throw new Error(
      `ambiguous id prefix "${prefix}", matches: ${matches.map((b) => b.shortId).join(", ")}`,
    );
  }
  return matches[0]!;
}

// ---------- lock ----------

interface LockStatus {
  locked: boolean;
  pid?: number;
  command?: string;
  running?: boolean;
}

async function checkLock(repo: string): Promise<LockStatus> {
  // Absolute, so the lock is read inside `repo` and not the server's cwd.
  const gitDir = (await git(repo, ["rev-parse", "--absolute-git-dir"])).trim();
  const lockPath = `${gitDir}/git-bug/lock`;
  const file = Bun.file(lockPath);
  if (!(await file.exists())) return { locked: false };
  const text = (await file.text()).trim();
  const pid = Number.parseInt(text, 10);
  if (!Number.isInteger(pid)) return { locked: false };
  // Confirm the pid is actually alive and fetch its command line, the way
  // git-bug itself validates the lock (process.IsRunning(pid)) before
  // reporting it as held; a stale lock file from a crash reports as free.
  const ps = await run(["ps", "-o", "pid=,command=", "-p", String(pid)]);
  const running = ps.code === 0 && ps.stdout.trim().length > 0;
  if (!running) return { locked: false };
  const command = ps.stdout.trim().replace(/^\d+\s+/, "");
  return { locked: true, pid, command, running: true };
}

async function requireUnlocked(repo: string): Promise<void> {
  const lock = await checkLock(repo);
  if (lock.locked) {
    throw new Error(
      `git-bug repository is locked by pid ${lock.pid} (${lock.command}). ` +
        `Close it (e.g. exit "git bug termui") and try again. Not retrying, not killing it.`,
    );
  }
}

// ---------- ssh key check ----------

// Plain git over SSH loads the key into ssh-agent (AddKeysToAgent), which
// git-bug's own client needs. ls-remote does that without touching any ref.
async function ensureSshKeyLoaded(repo: string, remote: string): Promise<void> {
  const r = await run(["git", "-C", repo, "ls-remote", remote, "HEAD"]);
  if (r.code !== 0) {
    throw new Error(
      `Cannot reach remote "${remote}" over git (${r.stderr.trim()}). ` +
        `If the SSH key is not loaded in ssh-agent, load it and try again; this tool will not load one for you.`,
    );
  }
}

// ---------- MCP server ----------

const server = new McpServer({ name: "git-bug-mcp", version: "0.1.0" });

const repoParam = z
  .string()
  .optional()
  .describe("Path to the git repository. Defaults to this server's cwd.");

// Values reach git and git-bug argv as positionals; anything starting with
// "-" would be parsed as a flag (e.g. `--upload-pack=...` or `-F <file>`).
const idParam = z.string().regex(/^[0-9a-f]{1,64}$/, "a bug id or hex prefix");
const labelParam = z.string().min(1).refine((v) => !v.startsWith("-"), "labels cannot start with '-'");
const remoteParam = z
  .string()
  .regex(/^[A-Za-z0-9_][A-Za-z0-9._\/-]*$/, "a remote name not starting with '-'")
  .optional()
  .default("origin");

function repoOrCwd(repo?: string): string {
  return repo ?? process.cwd();
}

function text(payload: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(payload, null, 2) }] };
}

function errorText(message: string) {
  return { content: [{ type: "text" as const, text: message }], isError: true };
}

server.registerTool(
  "bug_list",
  {
    title: "List git-bug bugs",
    description:
      "List bugs from refs/bugs/* by reading git plumbing directly (lock-free, works even while `git bug termui` holds git-bug's lock). Sorted by last update, most recent first.",
    inputSchema: {
      repo: repoParam,
      status: z.enum(["open", "closed", "all"]).optional().default("all"),
      label: z.array(z.string()).optional().describe("Only bugs carrying every given label."),
      query: z.string().optional().describe("Case-insensitive substring match on title, description or comments."),
      author: z.string().optional().describe("Substring match on the bug author's name or email."),
    },
  },
  async ({ repo, status, label, query, author }) => {
    try {
      const repoPath = repoOrCwd(repo);
      const [bugs, identities] = await Promise.all([loadAllBugs(repoPath), loadIdentities(repoPath)]);
      const q = query?.toLowerCase();
      const a = author?.toLowerCase();
      const filtered = bugs.filter((bug) => {
        if (status && status !== "all" && bug.status !== status) return false;
        if (label && !label.every((l) => bug.labels.has(l))) return false;
        if (a) {
          const identity = identities.get(bug.authorId);
          const hay = `${identity?.name ?? ""} ${identity?.email ?? ""}`.toLowerCase();
          if (!hay.includes(a)) return false;
        }
        if (q) {
          const hay = [bug.title, bug.description.message, ...bug.comments.map((c) => c.message)]
            .join("\n")
            .toLowerCase();
          if (!hay.includes(q)) return false;
        }
        return true;
      });
      filtered.sort((x, y) => y.updatedAt - x.updatedAt);
      return text(
        filtered.map((bug) => ({
          id: bug.shortId,
          title: bug.title,
          status: bug.status,
          labels: [...bug.labels],
          created: new Date(bug.createdAt * 1000).toISOString(),
          updated: new Date(bug.updatedAt * 1000).toISOString(),
          comments: bug.comments.length,
        })),
      );
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_show",
  {
    title: "Show a git-bug bug",
    description:
      "Show full detail for one bug by id prefix, reading git plumbing directly (lock-free). Errors on an ambiguous prefix.",
    inputSchema: {
      repo: repoParam,
      id: idParam.describe("Bug id or a unique prefix of it (e.g. the 7-char short id)."),
    },
  },
  async ({ repo, id }) => {
    try {
      const repoPath = repoOrCwd(repo);
      const [bugs, identities] = await Promise.all([loadAllBugs(repoPath), loadIdentities(repoPath)]);
      const bug = resolveBugByPrefix(bugs, id);
      const identityOf = (authorId: string) => {
        const identity = identities.get(authorId);
        return { name: identity?.name ?? "unknown", email: identity?.email ?? "" };
      };
      return text({
        id: bug.shortId,
        title: bug.title,
        status: bug.status,
        labels: [...bug.labels],
        author: identityOf(bug.authorId),
        created: new Date(bug.createdAt * 1000).toISOString(),
        updated: new Date(bug.updatedAt * 1000).toISOString(),
        description: {
          author: identityOf(bug.description.authorId),
          time: new Date(bug.description.timestamp * 1000).toISOString(),
          message: bug.description.message,
          edited: bug.description.edited,
        },
        comments: bug.comments.map((c) => ({
          author: identityOf(c.authorId),
          time: new Date(c.timestamp * 1000).toISOString(),
          message: c.message,
          edited: c.edited,
        })),
      });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_labels",
  {
    title: "List git-bug labels in use",
    description: "List every label currently applied to any bug, with how many bugs carry it. Lock-free.",
    inputSchema: { repo: repoParam },
  },
  async ({ repo }) => {
    try {
      const bugs = await loadAllBugs(repoOrCwd(repo));
      const counts = new Map<string, number>();
      for (const bug of bugs) {
        for (const l of bug.labels) counts.set(l, (counts.get(l) ?? 0) + 1);
      }
      const rows = [...counts.entries()]
        .sort((a, b) => b[1] - a[1])
        .map(([label, count]) => ({ label, count }));
      return text(rows);
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "identity_list",
  {
    title: "List git-bug identities",
    description: "List identities from refs/identities/*, read directly (lock-free).",
    inputSchema: { repo: repoParam },
  },
  async ({ repo }) => {
    try {
      const identities = await loadIdentities(repoOrCwd(repo));
      return text([...identities.values()]);
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_lock_status",
  {
    title: "Check git-bug's repository lock",
    description:
      "Report whether git-bug's own cache lock (.git/git-bug/lock) is held, and by which pid and command. Never kills the process.",
    inputSchema: { repo: repoParam },
  },
  async ({ repo }) => {
    try {
      const lock = await checkLock(repoOrCwd(repo));
      return text(lock);
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_create",
  {
    title: "Create a git-bug bug",
    description:
      "Create a new bug through the real `git bug` CLI (non-interactive). Refuses if git-bug's lock is held.",
    inputSchema: {
      repo: repoParam,
      title: z.string(),
      message: z.string(),
      labels: z.array(labelParam).optional().default([]),
    },
  },
  async ({ repo, title, message, labels }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await requireUnlocked(repoPath);
      const r = await run(
        ["git-bug", "bug", "new", "--non-interactive", "-t", title, "-m", message],
        { cwd: repoPath },
      );
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      const created = r.stdout.trim();
      const id = created.match(/^([0-9a-f]{7,})/)?.[1];
      if (!id) throw new Error(`bug created but its id could not be read from: ${created}`);
      if (labels && labels.length > 0) {
        const lr = await run(["git-bug", "bug", "label", "new", id, ...labels], { cwd: repoPath });
        // The bug exists now: report its id so a retry labels it instead of filing a duplicate.
        if (lr.code !== 0) return errorText(`created ${id}, but labeling failed: ${lr.stderr.trim() || lr.stdout.trim()}`);
      }
      return text({ created });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_comment",
  {
    title: "Comment on a git-bug bug",
    description: "Add a comment through the real `git bug` CLI (non-interactive). Refuses if git-bug's lock is held.",
    inputSchema: { repo: repoParam, id: idParam, message: z.string() },
  },
  async ({ repo, id, message }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await requireUnlocked(repoPath);
      const r = await run(
        ["git-bug", "bug", "comment", "new", "--non-interactive", "-m", message, id],
        { cwd: repoPath },
      );
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      return text({ result: r.stdout.trim() || "ok" });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_label",
  {
    title: "Change a git-bug bug's labels",
    description: "Add and/or remove labels through the real `git bug` CLI. Refuses if git-bug's lock is held.",
    inputSchema: {
      repo: repoParam,
      id: idParam,
      add: z.array(labelParam).optional().default([]),
      remove: z.array(labelParam).optional().default([]),
    },
  },
  async ({ repo, id, add, remove }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await requireUnlocked(repoPath);
      const results: string[] = [];
      if (add && add.length > 0) {
        const r = await run(["git-bug", "bug", "label", "new", id, ...add], { cwd: repoPath });
        if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
        results.push(r.stdout.trim());
      }
      if (remove && remove.length > 0) {
        const r = await run(["git-bug", "bug", "label", "rm", id, ...remove], { cwd: repoPath });
        if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
        results.push(r.stdout.trim());
      }
      return text({ result: results.join("\n") || "nothing to do" });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_status",
  {
    title: "Open or close a git-bug bug",
    description: "Set a bug's status through the real `git bug` CLI. Refuses if git-bug's lock is held.",
    inputSchema: { repo: repoParam, id: idParam, status: z.enum(["open", "closed"]) },
  },
  async ({ repo, id, status }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await requireUnlocked(repoPath);
      const sub = status === "open" ? "open" : "close";
      const r = await run(["git-bug", "bug", "status", sub, id], { cwd: repoPath });
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      return text({ result: r.stdout.trim() || "ok" });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_title",
  {
    title: "Rename a git-bug bug",
    description: "Edit a bug's title through the real `git bug` CLI (non-interactive). Refuses if git-bug's lock is held.",
    inputSchema: { repo: repoParam, id: idParam, title: z.string() },
  },
  async ({ repo, id, title }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await requireUnlocked(repoPath);
      const r = await run(
        ["git-bug", "bug", "title", "edit", "--non-interactive", "-t", title, id],
        { cwd: repoPath },
      );
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      return text({ result: r.stdout.trim() || "ok" });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_push",
  {
    title: "Push git-bug refs to a remote",
    description:
      "PUBLISHES every local bug and identity to everyone with access to the remote, so call it only when the user approved this push: runs plain `git push <remote> refs/bugs/*:refs/bugs/* refs/identities/*:refs/identities/*` (lock-free, no git-bug CLI involved). Never force-pushes. A rejected (non-fast-forward) ref is reported, not retried; run bug_pull first.",
    inputSchema: { repo: repoParam, remote: remoteParam },
  },
  async ({ repo, remote }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await ensureSshKeyLoaded(repoPath, remote);
      const r = await run(
        ["git", "push", remote, "refs/bugs/*:refs/bugs/*", "refs/identities/*:refs/identities/*"],
        { cwd: repoPath },
      );
      const diverged = /\[rejected\]|non-fast-forward/i.test(r.stderr);
      if (r.code !== 0 && diverged) {
        return errorText(
          `Push rejected, at least one ref diverged from ${remote}: run bug_pull first.\n${r.stderr.trim()}`,
        );
      }
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      return text({ result: r.stderr.trim() || r.stdout.trim() || "ok" });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

server.registerTool(
  "bug_pull",
  {
    title: "Pull git-bug refs from a remote",
    description: "Pull bugs and identities through the real `git bug pull` CLI. Refuses if git-bug's lock is held.",
    inputSchema: { repo: repoParam, remote: remoteParam },
  },
  async ({ repo, remote }) => {
    try {
      const repoPath = repoOrCwd(repo);
      await requireUnlocked(repoPath);
      await ensureSshKeyLoaded(repoPath, remote);
      const r = await run(["git-bug", "pull", remote], { cwd: repoPath });
      if (r.code !== 0) throw new Error(r.stderr.trim() || r.stdout.trim());
      return text({ result: r.stdout.trim() || "ok" });
    } catch (err) {
      return errorText(String(err instanceof Error ? err.message : err));
    }
  },
);

const transport = new StdioServerTransport();
await server.connect(transport);
