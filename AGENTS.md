# Dotfiles project guide

This repository provisions personal developer tools and maintains shared agent instructions. This file describes the repository; agents/AGENTS.md is a separate, globally linked personal policy. Do not copy that policy into other projects.

## Where things live

- agents/skills/: reusable skill entry points and their supporting resources.
- agents/AGENTS.md: shared workflow conventions, linked into each harness by the switch (nix/home/common.nix).
- evals/: end-to-end harness evals. Each scenarios/*.yaml is one real multi-turn session: the seed repository files, then turns of a prompt and its expected behavior (skills read, commands run, branch and push state, shell checks, files, PR fields). Each scenario names the skills it exercises; `bun evals/run.ts --run` runs only the core scenarios, `--skill <name>` the ones for one skill, `--all` everything. run.ts is the only code that interprets them; models.json lists the models. Results under results-*/ are ignored. Everything is YAML, JSON or Bun TypeScript: no Python, no per-scenario check code, and no tests of the runner. When a scenario needs logic the expectation keys cannot express, prefer a shell `check` over a new key.
- openspec/changes/: proposed contracts and implementation tasks. Main specs describe merged work only.
- flake.nix and nix/: machine provisioning, the only declaration of the workspace. nix/home/common.nix holds what both platforms get (packages, live links into this repository, setup steps), nix/home/linux.nix and nix/home/darwin.nix what one platform gets, nix/darwin/ the macOS system state and Homebrew (casks, three formulas, App Store apps, pinned taps), nix/pkgs/ the tools packaged from upstream binaries, nix/apps.nix the `switch` and `upgrade` commands. macos.sh and linux.sh only install Nix and run the first switch. Switching changes the host; do not switch as validation, run the checks under verify/ instead. Nix reads this repository as a git flake, so stage a new file before a switch or `nix build` in place sees it.
- verify/: the setup checks. verify/packages/ checks every declared package on every platform, verify/linux/ provisions a throwaway Ubuntu container, verify/macos/ evaluates or builds the macOS configuration, verify/macos-vm/ switches a disposable macOS VM. verify/README.md explains why macOS has two checks.
- claude/, opencode/, and other application directories: tool-specific configuration. Inspect the links nix/home/ declares for them before changing managed files.

## Delegation

Mechanical stretches go to a subagent one tier below the orchestrator: the `verification` skill, evals scenario and fixture work, and transcript review. Adversarial reviewers stay at the orchestrator's tier, because a reviewer that misses the bug saves nothing. A paid eval run starts in the session that started it and never in a subagent, since killing the subagent kills the run.

## Updating the harness

Start from an observed failure and name the decision that should change. Trace every instruction that can control that decision before editing: shared invariants belong once in agents/AGENTS.md, workflow-specific procedure belongs in the owning agents/skills/<name>/SKILL.md, and repository commands or paths belong here. Replace conflicting guidance at its source instead of appending a later exception. Search for stale variants after the edit.

Write for execution, not explanation. Use one stable term per concept and express each rule as a trigger, required action, and stop condition or exception. Put the decisive instruction before the step it governs. Keep rationale only when it prevents a likely misreading; omit history, repeated summaries, decorative examples, and duplicated global policy from skills. Prefer deleting obsolete text to adding precedence prose. Spend tokens on irreversible boundaries, ownership, and machine-checkable outcomes.

Prove the behavior through the smallest existing disposable scenario that covers the decision. Add a new scenario or turn only for an observed gap, declare its expectations before running it, and keep prompts limited to the context the agent would actually receive. Run the free wiring check `bun evals/run.ts --dry-run` first, then run the paid scenarios and review their transcripts. Never edit generated run evidence.

## Verification

Run checks from the repository root. The eval runner and forge stub are Bun with standard-library TypeScript; scenario checks are shell lines that use git, bun and jq. Git and authenticated pi (via pi-agent) with access to the requested models are needed for behavioral runs; OpenSpec is needed to validate change artifacts. Eval providers run gpt-6.1-sol and gpt-6-luna, never gpt-6-astra.

For evals/ code: `bun evals/run.ts --dry-run` validates every scenario's shape, seeds its repository and evaluates each turn's expectations against seed state (expect failures there; it proves the wiring, not the behavior). For an OpenSpec change under openspec/changes/: `openspec validate <change-id> --strict`. For a skill under agents/skills/: `uv run --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py agents/skills/<name>` checks frontmatter only. It ships with the Codex system skills, not this repository, and is unavailable without Codex and uv. No general application build or repository-wide test suite is declared.

For changes to agent instructions: `bun evals/run.ts --run --skill <name>` after a change to one skill, `--all` after a change to agents/AGENTS.md or a model, executes the paid scenarios and retains ignored results-*/ evidence with transcripts; review every transcript before claiming acceptance. Local dry-run success does not establish harness acceptance. `--run` starts real sessions and consumes usage allowance. Both the local checks and that behavioral evidence must pass before reporting the harness validated.

Validate edited JSON with python3 -m json.tool <path>. No check should install tools, deploy, expose secrets, or modify external services merely to establish documentation accuracy.

### Verifying a setup change

This is a different question from verifying a harness change, and the two are not interchangeable. A harness change alters how a model behaves, so it is judged by running sessions and reading transcripts, which is probabilistic and paid: that is the section above. A setup change alters what a machine ends up with, which is a deterministic question with a yes or no answer, so it is judged by provisioning a machine from nothing and asserting the result.

**Why it is checkable at all.** Provisioning is one declaration, applied by one command per platform, so a machine is reproduced rather than accumulated:

- **Everything is declared, nothing is scripted.** flake.nix and nix/ list every package, cask, App Store app, link, macOS setting and setup step, and flake.lock pins every input, Homebrew and its taps included. Adding a tool is a line in a package list; upgrading is `nix run .#upgrade`, which updates the pins and switches. Items the declaration cannot own are named in README.md ("Manual steps"), and openspec/changes/provision-with-nix/coverage.tsv maps every item the workspace had before Nix to its declared source.
- **A switch is idempotent.** home-manager and nix-darwin compute the result from the declaration, so a second switch with no change keeps the same generation, writes no backup file and duplicates no shell block. Setup steps that are not packages (herdr integrations and plugins, the codex config merge, the bat cache, agent-browser's Chrome, Neovim plugins) are activation steps that check their own state before acting.
- **Removal is part of provisioning.** A link or package dropped from the declaration is removed by the next switch, and on macOS so are Homebrew formulas and casks the declaration does not list.
- **A failed step costs one step, not the switch.** Each setup step that reaches the network or a running server reports its own failure or skip by name and lets the others run.

**What the check is.** Each check copies the working tree (without .git and secrets) somewhere disposable and applies it there:

- `verify/packages/run.sh` evaluates the package lists for aarch64-darwin, aarch64-linux and x86_64-linux and checks each package is prebuilt on cache.nixos.org and that no two provide the same file. It needs Docker.
- `verify/linux/run.sh` builds a bare Ubuntu container, runs `linux.sh` (Nix install and switch), asserts, runs it again, asserts again, and checks the second run kept the generation, left no backups and duplicated no shell block. It needs Docker. `--platform linux/amd64` checks the other architecture.
- `verify/macos/run.sh` evaluates the darwin configuration (in a container when this Mac has no Nix) or builds it without activation (when it has), and asserts every link, step, launch agent, setting and Homebrew item it would apply.
- `verify/macos-vm/run.sh` runs `macos.sh` in a disposable macOS VM, twice, and asserts the result. It needs Nix on this Mac (tart comes from nixpkgs) and must pass before a switch on a real Mac.

**What the assertions look for**: every tool answers its version command (or, for a language server without one, an LSP initialize request) rather than merely existing on PATH; every tracked config resolves through `readlink -f` to the file in this repository, so a copy with matching contents fails; non-interactive shells find the tools, which is what an agent hook or a herdr pane gets; and a step that was skipped says so, because a silent skip is indistinguishable from a step that worked.

Run the check for the platform the change touches, both when it touches both, and report the counts. A green run is evidence; a change to the declaration with no run behind it is unverified, however obviously correct it reads.

## Working state

Expect locally managed files to be dirty after tool updates. Preserve changes outside the task and stage explicit files. Inspect root and nested instruction scope and symlink destinations before edits. Record unavailable checks as unverified, never as passing. A completed model turn or passing tests written against a guessed requirement are not evidence that the intended task is complete.
