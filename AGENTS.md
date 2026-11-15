# Dotfiles project guide

This repository provisions personal developer tools and maintains shared agent instructions. This file describes the repository; agents/AGENTS.md is a separate, globally linked personal policy. Do not copy that policy into other projects. AGENTS.md is the instruction source of truth; CLAUDE.md must remain a relative symlink to it.

## Where things live

- agents/skills/: the explicit-only sjdonado-mode entry point. agents/modes/sjdonado-mode/ owns private development playbooks, local helper skills, and pinned public principles outside discovery. agents/README.md explains activation and layout.
- agents/AGENTS.md: shared boundaries and available capabilities, linked into each harness by `setup/lib/links.sh`.
- agents/eval/: area-indexed manual harness evals and observations. agents/README.md explains when to run them; agents/eval/README.md owns the procedure.
- adrs/: concise reasoning and learnings behind major setup decisions. Read relevant records before revisiting a decision; add a record only when the rationale is worth preserving, not for routine edits or task tracking.
- setup/: provisioning declarations, libraries, host accounts, platform assets, and checks. Root setup.sh and sync.sh are stable entry points. setup/README.md owns the layout and operating guidance; setup/verify/README.md explains platform checks. Application configurations remain in their root-level app directories.
- claude/, opencode/, and other application directories: tool-specific configuration. Inspect `setup/lib/links.sh` before changing managed files.

## Delegation

Delegate substantial independent work when its benefit exceeds coordination cost; run short checks and edits in the current session. Mechanical work and transcript review can use a model one tier below the orchestrator. Independent review is optional and stays at a capable tier when a concrete concern justifies it.

## Updating the harness

Start from an observed failure and name the decision that should change. Trace every instruction that can control that decision before editing: rules that must hold on every turn belong once in agents/AGENTS.md, a rule a step applies belongs in its `principle-*` skill, a reusable step in its building block, workflow-specific procedure in the owning workflow's SKILL.md, and repository commands or paths here. Replace conflicting guidance at its source instead of appending a later exception. Search for stale variants after the edit.

Write for execution, not explanation. Use one stable term per concept and express each rule as a trigger, required action, and stop condition or exception. Put the decisive instruction before the step it governs. Keep rationale only when it prevents a likely misreading; omit history, repeated summaries, decorative examples, and duplicated global policy from skills. Prefer deleting obsolete text to adding precedence prose. Spend tokens on irreversible boundaries, ownership, and machine-checkable outcomes.

Use agents/README.md to decide when harness evals are needed and agents/eval/README.md for selection and execution. Update a case when an observed failure exposes a gap; preserve historical observations as evidence of their original instruction revision.

## Verification

Run repository commands from the root. Harness behavior uses the focused eval guidance above; setup changes use setup/verify/. Report actual evidence and limitations. A parser result or completed model turn does not establish behavior, and unavailable checks remain unverified.

For a skill: `uv run --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-path>` checks frontmatter only; private local helpers live under agents/modes/sjdonado-mode/skills/. Vendored upstream metadata may use fields this validator does not recognize; preserve vendor bytes and check YAML and provenance separately. Validate edited JSON with `python3 -m json.tool <path>`. These structural checks do not establish model behavior. No general application build or repository-wide test suite is declared. Checks must not deploy, expose secrets or modify external services merely to establish documentation accuracy.

### Verifying a setup change

Run `setup/verify/macos.sh` for macOS changes and `setup/verify/linux.sh --platform linux/arm64` plus `--platform linux/amd64` for Linux changes; run both platforms when both are affected. Follow setup/verify/README.md, report counts and limitations, and inspect final assertions. Do not apply host state just to validate a declaration. Host application and `sync.sh --check` are separate from disposable verification.

## Accounts and machines

The setup supports any number of accounts on one Mac and is used with two. Real hostname and account names appear only in `setup/lib/hosts/macos.sh`. Docs, checks, ADRs, commits and PR text refer to "the primary account" and "the second account" (or `<user>`, `<hostname>`), never to the real names. A check reads accounts from the host declaration. The GitHub owner in repository URLs and tap names is not an account name and stays.

## Working state

Expect locally managed files to be dirty after tool updates. Preserve changes outside the task and stage explicit files. Inspect root and nested instruction scope and symlink destinations before edits. Record unavailable checks as unverified, never as passing. A completed model turn or passing tests written against a guessed requirement are not evidence that the intended task is complete.
