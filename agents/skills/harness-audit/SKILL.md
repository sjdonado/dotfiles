---
name: harness-audit
description: Audit how the agent harness performed in one project from its residue (branch notes, PR bodies, OpenSpec changes, session transcripts) and recommend fixes. Read-only. Use for "how is the harness doing here"; the project's AGENTS.md content is harness-boostrap's job.
---

Report how the workflows actually behaved in this project, with evidence, and recommend the smallest fixes. Make no edits, no commits, no forge writes, no model sessions. Never read a transcript whole; extract the named signals with grep or jq and quote a bounded window.

1. Scope. Resolve the repository root and default branch. Take the window from the request, else the last 30 days. Note which instruction files apply (root, nested, globally linked) but leave their content to `harness-boostrap`; the question here is whether the workflows they define were followed and paid off.

2. Read the residue, cheapest first. For each source record a coverage line: the resolved path or command, how many items were read, or why it was zero.
   - Branch notes under `.agent/` in this checkout and in every `git worktree list` entry. They are excluded, never committed, so they exist only in the worktree that wrote them: if none has the directory, that is an unknown, not a finding. Decode filenames (`%2F` to `/`, then `%25` to `%`) before comparing with `git branch --all`. Flag a note that claims completion while its PR is unmerged (`gh pr view <branch> --json state`; no PR at all is itself the finding, not an unreadable source), names a checkpoint that fails `git merge-base --is-ancestor <sha> <branch>`, or carries an event log or copied tasks instead of references.
   - PRs in the window: `gh pr list --state all --limit 50 --search "updated:>=<window start>" --json number,title,body,url,mergedAt,headRefName`. For agent-driven branches check the body carries Assumptions and Rejected review findings, still matches the final diff, and that one line of work did not get a second PR.
   - Commits in the window: Conventional Commits compliance, WIP checkpoints left on merged branches, implementation commits on the default branch.
   - `openspec/changes/` when present: changes whose PR merged but were never archived; `openspec/specs/` empty while changes accumulate.
   - Session transcripts when readable. Claude Code: directories under `~/.claude/projects/` named by the absolute cwd with every non-alphanumeric character replaced by `-`; list the directory and match both the encoded project path and worktree directories carrying the repository basename (`-claude-worktrees-<repo>-`, `-herdr-worktrees-<repo>-`) rather than constructing names. A session is the top-level `<id>.jsonl`; its `<id>/subagents/` and `<id>/tool-results/` subtrees are a blind spot to name under Unknowns, not extra sessions. Codex: `~/.codex/sessions/<yyyy>/<mm>/<dd>/rollout-*.jsonl` whose first line's `jq -r 'select(.type=="session_meta").payload.cwd'` is the repository root or one of its worktrees. Take the most recent ten sessions in the window at most. Signals: a routing announcement then a different workflow; the same skill file read more than once in a session; interrupts (`[Request interrupted by user` in Claude Code, `turn_aborted` in Codex); permission denials; a stop to ask something a repository search answers; a completion claim the diff or checks contradict. Quote the line, never paraphrase sentiment.
   - `bench/` when the project has it: the latest batch result and what it leaves untested.

3. Weigh. A finding is a pattern with at least two occurrences or one with a concrete cost (lost requirement, wrong PR body, wasted sessions). One odd session is an anecdote and goes under unknowns.

4. Report:
   - **Coverage**: the per-source lines from step 2. Commits alone are not workflow residue: without at least one branch note, agent-driven PR body, or readable transcript, the result is "not auditable here" and there is no verdict.
   - **Verdict**: one paragraph, what works here and what does not.
   - **Findings**: numbered, each with the claim, the evidence as `path:line`, a session id, or a PR URL, and the smallest change that would fix it (an instruction edit, a `harness-boostrap` run, a `land` run, a bench scenario). Never a plan.
   - **Unknowns**: sources that were unreadable, empty, or too thin, and what would settle them.
