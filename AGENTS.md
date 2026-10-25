# Dotfiles project guide

This repository provisions personal developer tools and maintains shared agent instructions. This file describes the repository; agents/AGENTS.md is a separate, globally linked personal policy. Do not copy that policy into other projects.

## Where things live

- agents/skills/: reusable skills in three kinds: `principle-*` (one rule each, never entered as a workflow), building blocks (one step each: worktree, verification, agent-review, open-pr, git-bug), and workflows that compose them (iteration, poc, yolo, feedback and the rest). agents/README.md explains the capabilities and optional recipes.
- agents/AGENTS.md: shared boundaries and available capabilities, linked into each harness by the switch (nix/home/common.nix).
- evals/: disposable benchmark scenarios with seed files, user prompts and parent-owned expectations. Benchmark through gpt-6-luna subagents, sending prompts in order and inspecting their actions and repository outcomes. evals/README.md describes preparation and checks. No Pi or OpenCode launcher is required. Results under results-*/ are ignored.
- openspec/changes/: proposed contracts and implementation tasks. Main specs describe merged work only.
- flake.nix and nix/: machine provisioning, the only declaration of the workspace. nix/home/common.nix holds what both platforms get (packages, live links into this repository, setup steps), nix/home/linux.nix and nix/home/darwin.nix what one platform gets, nix/darwin/ the macOS system state and Homebrew (casks, the formulas nixpkgs lacks, pinned taps), nix/pkgs/ the tools packaged from upstream binaries, nix/apps.nix the `sync` and `upgrade` commands. setup.sh only installs Nix, repairs what keeps a switch from running, and runs the first switch; sync.sh runs the `sync` (or `upgrade`) command and then the host checks. Switching changes the host; do not switch as validation, run the checks under verify/ instead. Nix reads this repository as a git flake, so stage a new file before a switch or `nix build` in place sees it.
- verify/: the setup checks, one self-contained script per check: verify/linux.sh provisions a throwaway Ubuntu container, verify/macos.sh evaluates or builds the macOS configuration without applying it. The host checks after a switch live in sync.sh (`sync.sh --check`). verify/README.md explains each.
- claude/, opencode/, and other application directories: tool-specific configuration. Inspect the links nix/home/ declares for them before changing managed files.

## Delegation

Delegate substantial independent work when its benefit exceeds coordination cost; run short checks and edits in the current session. Mechanical eval fixture work and transcript review can use a model one tier below the orchestrator. Independent review is optional and stays at a capable tier when a concrete concern justifies it. The parent owns benchmark setup, prompt delivery and outcome assessment; the gpt-6-luna subagent performs the task.

## Updating the harness

Start from an observed failure and name the decision that should change. Trace every instruction that can control that decision before editing: rules that must hold on every turn belong once in agents/AGENTS.md, a rule a step applies belongs in its `principle-*` skill, a reusable step in its building block, workflow-specific procedure in the owning workflow's SKILL.md, and repository commands or paths here. Replace conflicting guidance at its source instead of appending a later exception. Search for stale variants after the edit.

Write for execution, not explanation. Use one stable term per concept and express each rule as a trigger, required action, and stop condition or exception. Put the decisive instruction before the step it governs. Keep rationale only when it prevents a likely misreading; omit history, repeated summaries, decorative examples, and duplicated global policy from skills. Prefer deleting obsolete text to adding precedence prose. Spend tokens on irreversible boundaries, ownership, and machine-checkable outcomes.

Prove the behavior through the smallest existing disposable scenario that covers the decision. Add a new scenario or turn only for an observed gap, declare its expectations before running it, and keep prompts limited to the context the agent would actually receive. Prepare the fixture, run its prompts through a gpt-6-luna subagent and review its transcript and artifacts. Keep expectations outside the child prompt. Never edit generated run evidence.

## Verification

Run checks from the repository root. For harness behavior, use direct gpt-6-luna subagents with disposable fixtures, as described in evals/README.md. Send only the live harness instructions, project context and current user prompt; retain later turns and expected outcomes in the parent. Inspect every tested turn before reporting acceptance. A provider failure is unverified, and a completed model turn is not proof of the expected behavior. Choose scenarios covering the changed decisions rather than requiring an entire matrix for every edit. No Pi or OpenCode benchmark dependency is needed.

For an OpenSpec change: `openspec validate <change-id> --strict`. For a skill: `uv run --with pyyaml python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py agents/skills/<name>` checks frontmatter only. Validate edited JSON with `python3 -m json.tool <path>`. These structural checks do not establish model behavior. No general application build or repository-wide test suite is declared. Checks must not deploy, expose secrets or modify external services merely to establish documentation accuracy.

### Verifying a setup change

This is a different question from verifying a harness change, and the two are not interchangeable. A harness change alters how a model behaves, so it is judged by running sessions and reading transcripts, which is probabilistic and paid: that is the section above. A setup change alters what a machine ends up with, which is a deterministic question with a yes or no answer, so it is judged by provisioning a machine from nothing and asserting the result.

**Why it is checkable at all.** Provisioning is one declaration, applied by one command per platform, so a machine is reproduced rather than accumulated:

- **Everything is declared, nothing is scripted.** flake.nix and nix/ list every package, cask, link, macOS setting and setup step, and flake.lock pins every input, Homebrew and its taps included. Adding a tool is a line in a package list; upgrading is `sync.sh --upgrade`, which updates the pins, switches and checks. Items the declaration cannot own are named in README.md ("Manual steps"), and openspec/changes/provision-with-nix/coverage.tsv maps every item the workspace had before Nix to its declared source.
- **A switch is idempotent.** home-manager and nix-darwin compute the result from the declaration, so a second switch with no change keeps the same generation, writes no backup file and duplicates no shell block. Setup steps that are not packages (the codex config merge, BrowserRouter's registration) are activation steps that check their own state before acting.
- **Removal is part of provisioning.** A link or package dropped from the declaration is removed by the next switch, and on macOS so are Homebrew formulas and casks the declaration does not list.
- **A failed step costs one step, not the switch.** Each setup step that reaches the network or a running server reports its own failure or skip by name and lets the others run.

**What the check is.** Each check copies the files in git's index, with their working-tree contents, somewhere disposable and applies them there:

- `verify/linux.sh` starts a bare Ubuntu container, runs `setup.sh --linux` (Nix install and switch), checks it with `sync.sh --check`, runs `setup.sh` and `sync.sh` again, and checks the second run kept the generation, left no backups and duplicated no shell block. It needs Docker. `--platform linux/amd64` checks the other architecture.
- `verify/macos.sh` evaluates the darwin configuration and asserts every link, step, launch agent, setting and Homebrew item it would apply. With Nix on this Mac it builds the system without activating it, otherwise it runs in a container; either way it checks every package of the macOS and Linux profiles is available, prebuilt on cache.nixos.org and collision-free.
- `sync.sh --check` asserts this machine after a switch: declared tools run, links resolve into this repository, settings hold, and non-interactive shells find the tools. It is read-only; the switch itself is the change, and `darwin-rebuild switch --rollback` undoes it. On macOS, from the primary account it checks every listed account.

**What the assertions look for**: every tool answers its version command (or, for a language server without one, an LSP initialize request) rather than merely existing on PATH; every tracked config resolves through `readlink -f` to the file in this repository, so a copy with matching contents fails; non-interactive shells find the tools, which is what an agent hook or an editor's terminal gets; and a step that was skipped says so, because a silent skip is indistinguishable from a step that worked.

Run the check for the platform the change touches, both when it touches both, and report the counts. A green run is evidence; a change to the declaration with no run behind it is unverified, however obviously correct it reads.

## Accounts and machines

The setup is agnostic to the accounts and machines it runs on. It supports any number of accounts on one Mac and is used with two. The real hostname and account names appear only in the `darwinConfigurations` entry in flake.nix. Docs, checks, OpenSpec artifacts, commit messages and PR text refer to "the primary account" and "the second account" (or `<user>`, `<hostname>`), never to the real names. A check that needs an account or host reads it from the configuration, or defaults to the current user and this Mac's hostname. The GitHub owner in repository URLs and tap names is not an account name and stays.

## Working state

Expect locally managed files to be dirty after tool updates. Preserve changes outside the task and stage explicit files. Inspect root and nested instruction scope and symlink destinations before edits. Record unavailable checks as unverified, never as passing. A completed model turn or passing tests written against a guessed requirement are not evidence that the intended task is complete.
