---
name: git-bug
description: Read, file, comment on, label and sync git-bug issues through its non-interactive CLI. Use in a repository that tracks issues with git-bug, for "file a bug", "list open bugs", "comment on bug X", "push the bugs".
---

Use git-bug v0.12.0 or later. Run `git bug version` first; stop if it is missing or older than v0.12.0. Recheck changed CLI behavior on later minor releases.

**Publication.** `git bug push` publishes every bug and every identity in the local store: it needs the user's approval for that push, per the shared policy's Authority and preservation section. Setting git-bug up is configuration only: it creates no bug and pushes nothing.

**Non-interactive execution.** Use CLI commands with explicit arguments; pass `--non-interactive` where supported. Do not launch a terminal or web UI for agent work. v0.12.0 allows concurrent CLI and UI processes without a repository-wide lock; do not stop an existing UI. A first cache rebuild after upgrading is expected. Never delete cache or lock files to bypass a failure; report a persistent error.

**Transport.** Before syncing, select native Git with `git config --local git-bug.git-transport git`. This opt-in v0.12.0 transport uses Git's SSH configuration and credential helpers, including authenticated HTTPS. Preserve remote URLs and SSH configuration. On authentication failure, report the failing transport and ask for the missing access; do not rewrite the remote or load SSH keys as a workaround. Inspect local ticket refs and the relevant remote's `refs/bugs/*` and `refs/identities/*`; `git bug pull <remote>` imports records without checking out source files. If remote records cannot be inspected or pulled, stop before assigning a number or creating an identity.

**One identity.** Pull before creating an identity. Run `git bug user` and match on `git config user.email`; adopt a match with `git bug user adopt <id>` and never create a second. With no match, create exactly one: `git bug user new --non-interactive -n "<user.name>" -e "<user.email>"`.

**Ticket numbers.** Before creating any bug or feature, read the project's AGENTS.md for its prefix and numbering convention. Use that prefix, such as `DIT` or `ZEN`; never hardcode one prefix across repositories. If no convention is recorded, infer it only from one consistent existing title pattern and record it in the project AGENTS.md. If none exists or prefixes conflict, ask before creating a ticket.

1. Pull the relevant remote ticket records, including closed tickets, before allocating a number. List all open and closed tickets as JSON with `git bug bug --status open,closed --format json`; never derive the maximum from an open-only or paginated display.
2. Preserve assigned numbers. Match titles against `^<PREFIX>-([1-9][0-9]*): `, escaping the prefix for the regular expression. The next number is one above the highest assigned number, or 1 if none exist. Use no zero padding, never fill gaps or recycle closed-ticket numbers, and do not renumber existing tickets while filing a new one. Stop on duplicate numbers or malformed/conflicting prefixes and report them for repair.
3. Use `<PREFIX>-<N>: <title>` for every new ticket. Retitles preserve the existing prefix and number. Use the git-bug entity ID for CLI operations; the title prefix is a human identifier, not a replacement for that ID.
4. Recheck the full set immediately before creation and verify prefix uniqueness afterwards. Concurrent git-bug writes are safe in v0.12.0, but allocating a human number is not atomic across agents or clones. On a collision, stop and report it rather than silently renumbering another ticket.

Record the durable convention in the project's AGENTS.md: its prefix, the title pattern, and allocation from the maximum across open and closed tickets after pulling remote records. Compute the next number each time; do not keep a stale next-number counter in documentation. Bulk numbering or repair is a separate task requiring explicit scope; preserve all fields other than the authorized titles.

**Commands.**

| need | command |
| --- | --- |
| list | `git bug bug --status open,closed --format json` (open-only filter: `git bug bug status:open`) |
| show | `git bug bug show <id>` |
| file | `git bug bug new --non-interactive -t "<PREFIX>-<N>: <title>" -m "<body>"` |
| comment | `git bug bug comment new <id> -m "<text>"` |
| label | `git bug bug label new <id> <label>` |
| retitle | `git bug bug title edit <id> -t "<title>"` |
| identities | `git bug user` |
| sync | `git bug pull`, then `git bug push` with approval |

Pass titles and bodies as separate argv values, never interpolated shell code. Use `-t` and `-m` for short, single-line text. For multiline reports and comments, prefer a UTF-8 body file or stdin with `-F`; preserve actual newlines instead of literal `\n` separators. In v0.12.0, `bug new -t "<PREFIX>-<N>: <title>" -F <file>` keeps the explicit title and uses the whole file as the body; use `-F -` for stdin. Never combine `-m` and `-F`. Verify the stored title and body after writing; if the body is malformed, correct the original message rather than adding a compensating comment.

**Bug shape.** One defect per bug. Search open bugs first and comment on a duplicate instead of filing a second. The title is the observable symptom with its surface: `<PREFIX>-<N>: <surface>: <what goes wrong>`. The body uses these labeled lines in order, omitting a line only when it has nothing to say, never `Repro`, `Expected` or `Actual`:

```
Repro: numbered steps from a known state, or "not reproduced" and how often it happens
Expected: what should happen
Actual: what happens, with exact error text
Env: commit or build, device, OS version
Evidence: log excerpt, screenshot path, or a path:line suspect
```

Add one `area/<surface>` label and `kind/bug`. Record the cause or fix in a comment, never by rewriting the report.

**Feature shape.** Filed the same way with `kind/feature`. The title is `<PREFIX>-<N>: <surface>: <capability>`, in the user's terms. The body always has `Problem` and `Done when`:

```
Problem: who hits what today, and why it matters
Proposal: the suggested behavior, if one exists
Done when: observable acceptance checks, one per line
Out of scope: what this request deliberately excludes
```
