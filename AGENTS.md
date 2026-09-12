# Dotfiles project guide

This repository provisions personal developer tools and maintains shared agent instructions. This file describes the repository; agents/AGENTS.md is a separate, globally linked personal policy. Do not copy that policy into other projects.

## Where things live

- agents/skills/: reusable skill entry points and their supporting resources.
- agents/AGENTS.md: shared workflow conventions, linked by macos.sh and linux.sh.
- bench/: disposable agent scenarios, transcript analysis, and verification instructions in bench/README.md. Generated runs are ignored.
- openspec/changes/: proposed contracts and implementation tasks. Main specs describe merged work only.
- macos.sh and linux.sh: machine provisioning and managed links. These scripts change the host; do not run them as validation.
- claude/, opencode/, and other application directories: tool-specific configuration. Inspect the relevant installer links before changing managed files.

## Verification

Run checks from the repository root. The benchmark uses Python 3's standard library. Git and an authenticated Codex CLI with access to the requested models are needed for behavioral probes; OpenSpec is needed to validate change artifacts.

For bench/ code: `bench/measure verify --local` compiles the Python modules, runs their offline regression checks, and checks whitespace in tracked and untracked bench and instruction files. For an OpenSpec change under openspec/changes/: `openspec validate <change-id> --strict`. For a skill under agents/skills/: `uv run --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py agents/skills/<name>` checks frontmatter only. It ships with the Codex system skills, not this repository, and is unavailable without Codex and uv. No general application build or repository-wide test suite is declared.

For changes to agent instructions: `bench/measure verify --behavior` inspects existing scenario results and returns nonzero for missing, stale, failing, or unreviewed coverage. Local tooling success does not establish harness acceptance. Follow bench/README.md for the transcript review record and the active change's scenarios. `bench/measure verify --behavior --run` explicitly starts missing paid model sessions, capped at 30 per retained batch. Never reset the batch to hide failure or exceed that budget. Both local and behavioral checks must pass before reporting the harness validated.

If installers are changed, validate syntax without executing them: sh -n macos.sh and bash -n linux.sh. Syntax alone is not enough for either: `verify/linux/run.sh` provisions a throwaway Ubuntu container from the working tree, twice, and asserts that every tool runs, every tracked config is linked, non-interactive shells resolve the tools, and a re-run changes nothing; it needs Docker, and a GitHub token when the host IP is busy. `verify/macos/run.sh` runs `macos.sh --links-only` against a throwaway HOME and asserts the same shape for links, since macOS cannot be containerised. Read verify/README.md before changing either. Validate edited JSON with python3 -m json.tool <path>. No check should install tools, deploy, expose secrets, or modify external services merely to establish documentation accuracy.

## Working state

Expect locally managed files to be dirty after tool updates. Preserve changes outside the task and stage explicit files. Inspect root and nested instruction scope and symlink destinations before edits. Record unavailable checks as unverified, never as passing. A completed model turn or passing tests written against a guessed requirement are not evidence that the intended task is complete.
