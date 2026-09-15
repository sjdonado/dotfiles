# Dotfiles project guide

This repository provisions personal developer tools and maintains shared agent instructions. This file describes the repository; agents/AGENTS.md is a separate, globally linked personal policy. Do not copy that policy into other projects.

## Where things live

- agents/skills/: reusable skill entry points and their supporting resources.
- agents/AGENTS.md: shared workflow conventions, linked by macos.sh and linux.sh.
- bench/: disposable agent scenarios, transcript analysis, and verification instructions in bench/README.md. Generated runs are ignored.
- openspec/changes/: proposed contracts and implementation tasks. Main specs describe merged work only.
- macos.sh, linux.sh, mise.toml and lib/links.sh: machine provisioning. mise.toml declares every tool that is not platform-specific and both scripts install from it; lib/links.sh holds every symlink this repository owns and is sourced by both, so each script keeps only what is genuinely platform-specific. These scripts change the host; do not run them as validation, run the checks under verify/ instead.
- verify/: the setup checks. verify/linux/ provisions a throwaway Ubuntu container, verify/macos/ runs macos.sh against a throwaway HOME. verify/README.md explains why the two differ.
- claude/, opencode/, and other application directories: tool-specific configuration. Inspect the relevant installer links before changing managed files.

## Updating the harness

Start from an observed failure and name the decision that should change. Trace every instruction that can control that decision before editing: shared invariants belong once in agents/AGENTS.md, workflow-specific procedure belongs in the owning agents/skills/<name>/SKILL.md, and repository commands or paths belong here. Replace conflicting guidance at its source instead of appending a later exception. Search for stale variants after the edit.

Write for execution, not explanation. Use one stable term per concept and express each rule as a trigger, required action, and stop condition or exception. Put the decisive instruction before the step it governs. Keep rationale only when it prevents a likely misreading; omit history, repeated summaries, decorative examples, and duplicated global policy from skills. Prefer deleting obsolete text to adding precedence prose. Spend tokens on irreversible boundaries, ownership, and machine-checkable outcomes.

Prove the behavior through the smallest existing disposable scenario that covers the decision. Add a new case only for an observed gap, declare its artifact and tool-action assertions before running it, and keep prompts limited to the context the agent would actually receive. Run `bench/measure verify --local` first, then follow bench/README.md for paid behavioral runs and transcript review. Never edit generated run evidence or reset a batch to make a failure disappear.

## Verification

Run checks from the repository root. The benchmark uses Python 3's standard library. Git and an authenticated Codex CLI with access to the requested models are needed for behavioral probes; OpenSpec is needed to validate change artifacts.

For bench/ code: `bench/measure verify --local` compiles the Python modules, runs their offline regression checks, and checks whitespace in tracked and untracked bench and instruction files. For an OpenSpec change under openspec/changes/: `openspec validate <change-id> --strict`. For a skill under agents/skills/: `uv run --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py agents/skills/<name>` checks frontmatter only. It ships with the Codex system skills, not this repository, and is unavailable without Codex and uv. No general application build or repository-wide test suite is declared.

For changes to agent instructions: `bench/measure verify --behavior` inspects existing scenario results and returns nonzero for missing, stale, failing, or unreviewed coverage. Local tooling success does not establish harness acceptance. Follow bench/README.md for the transcript review record and the active change's scenarios. `bench/measure verify --behavior --run` explicitly starts missing paid model sessions, capped at 32 per retained batch. Never reset the batch to hide failure or exceed that budget. Both local and behavioral checks must pass before reporting the harness validated.

Validate edited JSON with python3 -m json.tool <path>. No check should install tools, deploy, expose secrets, or modify external services merely to establish documentation accuracy.

### Verifying a setup change

This is a different question from verifying a harness change, and the two are not interchangeable. A harness change alters how a model behaves, so it is judged by running sessions and reading transcripts, which is probabilistic and paid: that is the section above. A setup change alters what a machine ends up with, which is a deterministic question with a yes or no answer, so it is judged by provisioning a machine from nothing and asserting the result.

**Why it is checkable at all.** Provisioning is written to be deterministic, and every part of it is shaped so a machine can be reproduced rather than accumulated:

- **Dependencies are declared, not scripted.** mise.toml is the tool list for both platforms; the Brewfile holds what is macOS-specific. Adding a tool is a line in a declaration, not another guarded installer block, so the same file produces the same tool set on a fresh box and on a five-year-old one. The handful of tools that cannot come from mise are named in mise.toml with the measured reason, so the exception list is auditable instead of implicit.
- **Linking is idempotent.** Every managed file is a symlink into this repository, created the same way on every run. A second run must be a no-op: no duplicated shell-rc block, no `.backup.<timestamp>` beside a file the script already owns. Where a run legitimately replaces something once (`herdr integration install claude` writes a real settings.json before the tracked one is linked over it), it happens on the first pass only.
- **Removal is part of provisioning.** Stopping the install of something is not the same as undoing it, so both scripts prune links this repository no longer ships, and only links it created.
- **A failed install costs one tool, not the run.** Installers that reach the network fail in ways the change under test did not cause. Each is guarded so provisioning finishes and reports, rather than aborting halfway and leaving a box in a state nobody can reason about.

**What the check is.** Syntax first, because it is free: `sh -n macos.sh`, `bash -n linux.sh` and `sh -n lib/links.sh`. That last one is why the shared linking code is a sourced shell file rather than mise tasks: shell embedded in TOML is invisible to this rung. Then the real one, which is provisioning from scratch somewhere disposable:

- `verify/linux/run.sh` builds a bare Ubuntu container, copies the working tree in (uncommitted changes included), runs `linux.sh --install`, asserts, runs it again, asserts again, and checks no shell-rc block was duplicated. It needs Docker, and a GitHub token when the host IP has spent the hour's anonymous API calls. `--platform linux/amd64` checks the other architecture.
- `verify/macos/run.sh` points HOME at a temporary directory and runs `macos.sh --links-only` twice, asserting every link and that the second pass replaced nothing. macOS cannot be containerised, so this covers linking only; Homebrew, mise's installs, the login shell, launchd and macOS defaults are verified by running the script for real.

**What the assertions look for**, on both platforms: every tool answers `--version` rather than merely existing on PATH, since a wrapper whose postinstall never ran is on PATH and still broken; every tracked config resolves through `readlink -f` to the file in this repository, so a copy with matching contents fails; non-interactive shells find the tools, which is what an agent hook or a herdr pane gets; and a step that was skipped says so, because a silent skip is indistinguishable from a step that worked.

Run the check for the platform the change touches, both when it touches both, and report the counts. A green run is evidence; a change to an installer with no run behind it is unverified, however obviously correct it reads.

## Working state

Expect locally managed files to be dirty after tool updates. Preserve changes outside the task and stage explicit files. Inspect root and nested instruction scope and symlink destinations before edits. Record unavailable checks as unverified, never as passing. A completed model turn or passing tests written against a guessed requirement are not evidence that the intended task is complete.
