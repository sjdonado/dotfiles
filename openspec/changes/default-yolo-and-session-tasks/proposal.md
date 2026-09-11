## Why

Three things cost the human money and attention every day. The harness hesitates to enter `yolo` from a plain implementation request or a handoff, so autonomous work needs coaxing into the mode that is supposed to be the default, while `proto`, the genuinely cheap mode, carries no such friction. Work outside an OpenSpec change has no task state a second session or a subagent can read, so what a session accomplished lives only in that session's own to-do list and dies with it. And every session runs at one model tier, so the model doing the planning is also the model grinding through implementation and verification, which is what makes a run expensive: the two `adversarial-review` subagents alone already double the tier's cost at the end of every run.

## What Changes

- Make `yolo` the default route for implementation. A plain implementation request, an approved plan, or a handoff that asks for work to be done enters `yolo` without asking. `proto` becomes opt-in: it runs when the human says prototype, spike, rough, or "let me try it first", not when the agent judges the requirements uncertain.
- Keep proposing OpenSpec for work worth documenting, and say so in one line rather than silently choosing plan mode.
- Add a session task ledger: an OpenSpec-shaped `tasks.md` kept beside the branch note when work is NOT under an OpenSpec change. It is ticked as work lands, read by subagents and later sessions, referenced by `handoff`, folded into an OpenSpec change if one is adopted mid-session, and deleted by `land`.
- Add model-tier delegation: the orchestrating agent offers to run implementation and verification in subagents at a cheaper tier before starting each, records the answer as a project default, and under `yolo` follows that recorded default or skips the offer rather than stopping for it. The guidance names no model, no effort level, and no rule about when to spawn a subagent; it describes the role split and leaves the choice to the agent.
- **BREAKING** for existing sessions in flight: a session that was relying on `proto` being entered automatically now gets `yolo` unless it asks for a prototype.

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
