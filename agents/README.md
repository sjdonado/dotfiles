# AI agents

Shared Claude Code and OpenCode commands, skills, and instructions.

## Lifecycle

```mermaid
flowchart TD
    subgraph INPUT["input"]
        ask_in["a bounded question"] --> ask["/ask"]
        ask -.->|escalates when bigger than one answer| ask

        research_in["a question or claim"] --> research["/research"]
        research --> ledger["finding ledger (F1, F2, ...)"]
        ledger --> ticket["/create-ticket (batch, one confirm)"]

        triage_in["a ticket or an error"] --> triage["/triage"]
        triage --> brief["plan brief"]
        brief -.->|evidence: kill query first, then confirm or refute| brief

        idea_in["an idea worth documenting"] --> explore["openspec-explore"]
        explore --> propose["openspec-propose / openspec-new-change"]
        propose --> change["openspec/changes/&lt;id&gt;/"]
        change --> grill["grill-me
        interactive, or self-grill:
        resolve what evidence can settle,
        surface only survivors"]
        grill --> updatechange["openspec-update-change
        folds the answers into the artifacts"]
        updatechange --> change

        proto_in["requirements that will not settle on paper"] --> proto["/proto
        build a slice, local rungs green,
        human tries it, fold feedback in"]
        proto --> protoledger["requirements ledger"]
        proto -.->|premise disproved: kill, record why| proto

        else_in["everything else"] --> planmode["native plan mode"]
        planmode -.->|never both: an approved change is already the contract| planmode

        change --> approval["approval"]
        planmode --> approval
        protoledger --> approval
    end

    subgraph BUILD["build"]
        approval --> yolo["/yolo"]
        yolo --> ladder["resolve oracle ladder
        project AGENTS.md, else task runner, else toolchain"]
        ladder --> implement["implement"]
        implement --> rungs["local rungs green"]
        rungs --> audit["audit diff vs requirements"]
        audit --> review["adversarial-review
        2 blind subagents, told the diff is wrong"]
        review --> commit["commit"] --> push["push"] --> pr["open PR
        body: Assumptions / Refuted evidence / Rejected review findings"]
        pr --> checks(["remote required checks green
        terminal state"])
    end

    subgraph AFTER["after"]
        checks --> verify["openspec-verify-change
        does the code match the spec"]
        checks --> feedback["/feedback
        a bullet list from you;
        deferred rounds apply only,
        a full round settles the debt"]
        checks --> addressreview["/address-review
        review threads, red CI"]
        checks --> sync["openspec-sync-specs
        fold deltas into specs"]
        sync --> archive["openspec-archive-change
        keep it as institutional memory"]
        verify --> merge["human merges"]
        feedback --> merge
        addressreview --> merge
        archive --> merge
    end
```

At any point the escalation contract can stop the run: three failures under three
different fixes, two attempts with no new information, a diff far past the implied
size, evidence contradicting the premise, or a first touch of a migration, CI
config, lockfile, shared contract, infrastructure, or auth surface that the
request did not name.

## Layout

- `commands/` - shared `/address-review`, `/ask`, `/create-ticket`, `/feedback`, `/land`, `/proto`, `/research`, `/triage`, and `/yolo` commands
- `skills/` - Agent Skills loaded on demand by both harnesses
- `AGENTS.md` - global instructions, linked as Claude Code's `CLAUDE.md` and OpenCode's `AGENTS.md`

Commands are reachable only as `/name`; unlike skills they are never auto-invoked by description matching. `AGENTS.md` therefore carries an intent-routing table so a naturally phrased request still follows the workflow designed for it, with that workflow's gates intact.

The setup scripts link the same command and skill directories into both harnesses. There are no copied wrappers, custom subagent definitions, custom tools, or search plugins; the only custom agent is the OpenCode Ollama primary profile.

Two routes reach an agreed contract, and `AGENTS.md` picks between them: the `openspec-*` skills when the reasoning is worth keeping after the PR merges, native plan mode otherwise. Never both, since an approved OpenSpec change is already the contract and re-planning it just adds a second gate over the same decisions. No custom `/plan` command shadows native plan mode. A third path, `/proto`, exists for requirements that cannot be settled on paper: cheap human-in-the-loop build iterations validated by the local ladder rungs only, ending in a requirements ledger that `/yolo` consumes as its contract, or in killing the premise. It never pushes and never opens a PR, so nothing reaches a PR except through `/yolo`.

The OpenSpec skills come from https://github.com/Fission-AI/OpenSpec and are tracked in `skills-lock.json` like any other upstream skill. They shell out to the `openspec` CLI, which the setup scripts install with bun. `release-openspec` is deliberately not installed: it releases the OpenSpec project itself. `openspec-apply-change` is installed but never routed to, because implementation goes through `/yolo`, which is what carries the oracle ladder, adversarial review, and the escalation contract.

`handoff` comes from https://github.com/mattpocock/skills and is slash-only (`disable-model-invocation: true`), so it never fires on its own: it compacts the conversation into a document in the OS temp directory, for a fresh agent to pick up. It is not in `AGENTS.md`'s routing table on purpose, since the useful moment to hand off is one only the human can judge.

Agent-initiated review is adversarial: `adversarial-review` carries both the protocol and the finding format. The reference it used to make to `caveman-review` is gone, because the skill already wrote the format out itself and the plugin skill advertised the same trigger phrases as the native review command, which is where a review request belongs.

Human-requested review uses that native command, never a workflow, and it is aimed at a diff the session did not write: an external pull request, or a branch inherited from elsewhere. Work produced in a session already passed `adversarial-review` before it was pushed, by reviewers deliberately denied the plan and the rationale, so pointing the native command at it again is a second opinion from a reviewer with strictly more anchoring and strictly less independence.

The upstream `code-review` skill is gone: its auto-trigger phrases fired review outside the human-invoked path, and being hash-locked they could not be disabled in place. Review reaches the harness's own command, and `AGENTS.md`'s routing prohibition is the control. The `caveman-*` skills are gone from here too, since the caveman plugin owns those bodies.

## Global versus project

`AGENTS.md` holds contracts, shapes, classes, and protocols, and must stay project-agnostic. Concrete commands, paths, provisioning, and available data sources belong in each repository's own `AGENTS.md` and worktrunk project config. Where a project declares nothing, a workflow infers it and records what it inferred, so a wrong guess is visible rather than silent.

This is what lets the same harness serve a large monorepo and a small side project in another language. A project with no telemetry, tracker, or CI degrades gracefully: runtime claims are marked unchecked, and the oracle ladder shortens rather than failing.

## No orchestration layer

A session already starts inside a worktree with an agent running, and the model can spawn subagents itself, so parallelism and supervision are prompt-level concerns. There is deliberately no scheduler, daemon, queue tool, or fan-out script here: the loop lives in `AGENTS.md`, the commands, and the skills.

Where per-stream state is needed, worktrunk already provides it. CI and review state ride on its PR object (`ci.ci_status`, `ci.review_state`) via `wt list --full`; escalation and attempt counts live in its per-branch vars (`git config worktrunk.state.<branch>.vars.*`), which survive an agent restart because they are stored in `.git`. Vars are used rather than the activity marker, because a marker is rewritten on every prompt and would erase an escalation.

Creating a stream needs no tooling of its own: `wty <branch> -- '<intent>'` makes a provisioned worktree and hands the terminal to an agent in one step.

Do not enable the worktrunk Claude Code plugin: its `UserPromptSubmit` hook writes the same per-branch marker slot an escalation would use.

## Skill updates

Upstream skills are tracked in `skills-lock.json`. The `.agents/skills` link exposes the existing shared skill directory to `skills.sh`; Claude Code and OpenCode continue loading that directory through their setup links.

Add one with `--agent universal`, which is what resolves to the `.agents/skills` link. Any other agent id writes the skill body somewhere else in the repo instead: `--agent claude-code` drops a full copy into `.claude/skills/`, where this repo keeps only symlinks, so the copy would drift from `agents/skills` the moment either side is updated.

```sh
npx skills@1 add <owner>/<repo> --skill <name> --agent universal -y
ln -s ../../.agents/skills/<name> .claude/skills/<name>
```

The second line is bookkeeping this repo tracks: `.claude/skills/` holds a committed symlink per skills.sh-installed skill, and current versions of the CLI copy into an agent directory rather than linking, so adding one by hand keeps that set complete. Both harnesses already load the whole directory through the setup links, so the symlink changes nothing at runtime.

Review upstream changes before committing them, then update project skills with:

```sh
npx skills@1 update --project --yes
```

Neither command belongs in `macos.sh`. The scripts provision a machine from what is committed, and the skills are committed, so a fresh clone already has them: adding an update there would mean every provisioning run silently pulls new upstream instructions and rewrites the hashes nobody reviewed, which is the opposite of what the lock file is for. `skills experimental_install` restores from the lock and is equally unnecessary for the same reason. Updating is a deliberate act with a diff to read, like bumping the herdr plugin ref.

`skills list` reports a skill's agents from its own bookkeeping, so one added with `--agent universal` does not list Claude Code. That field is cosmetic here: both harnesses load the whole directory through the setup links, not per skill.

Never edit a locked skill body in place, or the next update will report drift or clobber the edit. A locked skill may only be deleted, along with its lock entry, or wrapped by local policy in `AGENTS.md`.

Deleting the body and leaving the entry is worse than leaving both: the entry is the instruction to fetch, so the next update reinstalls the skill. That is how the `caveman-*` and `code-review` bodies came back months after being removed. Deleting a skill therefore means the directory, the lock entry, and the `.claude/skills` symlink together.

`adversarial-review`, `evidence`, and `grill-me` are maintained locally and are not in the lock file. `grill-me` was unlocked deliberately: its upstream body was a one-line pointer to a command that does not exist.

There is no progress-tracking skill and no `AGENT_PROGRESS.md`. Run state is derivable from cheaper sources that cannot go stale: the oracle ladder says what is still failing, `git log` says what landed, `wt config state vars` holds attempts and escalations in `.git`, and a `tasks.md` in an OpenSpec change directory carries the checklist for specced work.

## Authentication

Authenticate each harness independently:

```sh
claude
opencode auth login
```

Use Claude Code directly for a Claude Pro/Max subscription. Do not route its OAuth credentials through OpenCode.

Configure MCP servers manually in each harness. OpenCode's public configuration is tracked under `opencode/`; credentials and generated runtime state stay machine-local. See `opencode/README.md`.

OpenCode documentation:

https://opencode.ai/docs/config/

https://opencode.ai/docs/mcp-servers/

Claude Code documentation:

https://code.claude.com/docs/en/mcp

## Ollama

Select the `ollama` primary profile instead of only switching the model. The profile uses `ollama/gemma4:e4b-mlx`, blocks delegation, and denies the current `linear_*` and `posthog_*` MCP tools so their schemas do not consume the local model's context.

When adding another OpenCode MCP server, also add its `<server-name>_*` deny rule to the `ollama` profile in `opencode/opencode.json`.
