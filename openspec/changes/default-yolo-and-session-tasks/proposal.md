## Why

Three things cost the human money and attention every day. The harness treats `yolo` and `proto` as interchangeable entry points and says nothing about which to reach for, so an expensive run, with its adversarial review, PR and remote checks, gets spent on requirements that are still moving, producing a PR that describes the wrong thing. The cheap mode should be the default and the expensive one should be entered deliberately. Work outside an OpenSpec change has no task state a second session or a subagent can read, so what a session accomplished lives only in that session's own to-do list and dies with it. And every session runs at one model tier, so the model doing the planning is also the model grinding through implementation and verification, which is what makes a run expensive: the two `adversarial-review` subagents alone already double the tier's cost at the end of every run.

## What Changes

- Make `proto` the default route into implementation whenever the contract is not already settled, and state `yolo`'s entry conditions explicitly: asked for by name or as a PR, an approved change or plan, a promoted `proto` ledger, a specified ticket, a round on a branch whose PR is open, or work small and bounded enough that its shape is not in question. Uncertainty routes to `proto`, never to `yolo`.
- Keep proposing OpenSpec for work worth documenting, and say so in one line rather than silently choosing plan mode.
- Add a session task ledger: an OpenSpec-shaped `tasks.md` kept beside the branch note when work is NOT under an OpenSpec change. It is ticked as work lands, read by subagents and later sessions, referenced by `handoff`, folded into an OpenSpec change if one is adopted mid-session, and deleted by `land`.
- Add model-tier delegation: the orchestrating agent offers to run implementation and verification in subagents at a cheaper tier before starting each, records the answer as a project default, and under `yolo` follows that recorded default or skips the offer rather than stopping for it. The guidance names no model, no effort level, and no rule about when to spawn a subagent; it describes the role split and leaves the choice to the agent.
- **BREAKING** for existing sessions in flight: a bare implementation request now opens a prototype loop rather than a pull request. Asking for a PR, or naming `yolo`, restores the old behavior.

## Capabilities

### New Capabilities

- `session-task-state`: task state for work that is not under an OpenSpec change, durable across sessions and readable by subagents.
- `model-tier-delegation`: the orchestrator role, and how work is delegated to a cheaper tier without naming models.

### Modified Capabilities

None. This repository has no synced main specs: `openspec/specs/` is empty because every change so far archives after its PR merges, and the routing behavior these deltas change lives in `agents/AGENTS.md` rather than in a spec. The routing default is specified as part of `session-task-state`, since the two are read together.

## Impact

Edits `agents/AGENTS.md` (the routing table, the planning section, and the continuity section), and the `yolo`, `proto`, `land`, and `handoff` skills under `agents/skills/`. Adds a session task ledger file convention under the already-ignored `.agent/` directory.

Behavioral acceptance applies: these are agent instructions, so `bench/measure verify --behavior` governs whether the change can be called validated, per `bench/README.md`. That is a paid batch and needs the human's authorization. It also collides with existing debt: `openspec/changes/improve-harness-effectiveness/` is unarchived at 17/20 with its own behavioral acceptance (tasks 3.5, 3.6, 4.4) still open, so the two changes compete for the same session budget.

No effect on the tools this repository provisions, on `bin/`, or on any application configuration.
