---
name: git-bug
description: Read, file, comment on, label and sync git-bug issues through its non-interactive CLI. Use in a repository that tracks issues with git-bug, for "file a bug", "list open bugs", "comment on bug X", "push the bugs".
---

The rules below were checked on git-bug v0.11. On another minor version, confirm the transport and identity behavior before relying on them. If `git bug version` fails, stop and report that git-bug is missing.

**Publication.** `git bug push` publishes every bug and every identity in the local store: it needs the user's approval for that push, per the shared policy's Publication authority. Setting git-bug up is configuration only: it creates no bug and pushes nothing.

**Never interactive.** Never launch `git bug termui` or `git bug webui`: they hold the repository lock for as long as they run, and a first run with no active identity creates a duplicate identity that the next push publishes. Pass `--non-interactive` where a command accepts it. When a command fails with "already locked by the process pid <n>", report that pid and wait for the user to release it; never kill it or remove `.git/git-bug/lock`.

**Transport.** git-bug's git client never uses git's credential helper: over HTTPS it is anonymous, so a private repository fails with "authentication required"; over SSH it uses only keys already in ssh-agent. When `origin` is an HTTPS forge URL, change only its URL to the SSH form (`git remote set-url origin git@<host>:<owner>/<repo>.git`). When `origin` is not on a forge the user's SSH config covers, ask first. Never edit `~/.ssh/config`. Before `git bug pull` or `push`, run `git fetch origin` so the SSH config loads the key, and confirm with `ssh-add -l`. "ssh: handshake failed ... no supported methods remain" means the agent is empty: fetch again and retry once, then ask; never load a key yourself.

**One identity.** Pull before creating an identity. Run `git bug user` and match on `git config user.email`; adopt a match with `git bug user adopt <id>` and never create a second. With no match, create exactly one: `git bug user new --non-interactive -n "<user.name>" -e "<user.email>"`.

**Commands.**

| need | command |
| --- | --- |
| list | `git bug bug` (filter: `git bug bug status:open`) |
| show | `git bug bug show <id>` |
| file | `git bug bug new -t "<title>" -m "<body>"` |
| comment | `git bug bug comment new <id> -m "<text>"` |
| label | `git bug bug label new <id> <label>` |
| retitle | `git bug bug title edit <id> -t "<title>"` |
| identities | `git bug user` |
| sync | `git bug pull`, then `git bug push` with approval |

Create and comment with `-t` and `-m` only; never `-F`, which deletes every line starting with `#` and takes the first line as the title.

**Bug shape.** One defect per bug. Search open bugs first and comment on a duplicate instead of filing a second. The title is the observable symptom with its surface: `<surface>: <what goes wrong>`. The body uses these labeled lines in order, omitting a line only when it has nothing to say, never `Repro`, `Expected` or `Actual`:

```
Repro: numbered steps from a known state, or "not reproduced" and how often it happens
Expected: what should happen
Actual: what happens, with exact error text
Env: commit or build, device, OS version
Evidence: log excerpt, screenshot path, or a path:line suspect
```

Add one `area/<surface>` label and `kind/bug`. Record the cause or fix in a comment, never by rewriting the report.

**Feature shape.** Filed the same way with `kind/feature`. The title is the capability in the user's terms with its surface. The body always has `Problem` and `Done when`:

```
Problem: who hits what today, and why it matters
Proposal: the suggested behavior, if one exists
Done when: observable acceptance checks, one per line
Out of scope: what this request deliberately excludes
```
