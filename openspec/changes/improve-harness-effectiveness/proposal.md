## Why

The existing Luna probe produced correct code but omitted its durable handoff, then invented a missing requirement and reported success in a fresh session (bench/handoff-v1-findings.md:12). Conflicting PR-update instructions and a no-OpenSpec landing gap also leave models to reconcile workflow policy, undermining the goal of a minimal, reusable harness.

## What Changes

- Add a standalone `harness-boostrap` skill to audit or set up project AGENTS.md files from repository evidence. Its output serves any capable coding agent and does not install personal workflows, require named skills, or import global policies.
- Bootstrap this repository's root AGENTS.md first, mapping changed surfaces to authoritative verification commands. Keep it separate from the shared personal instructions at agents/AGENTS.md.
- Add one discoverable verification entry point that separates tooling checks from required behavioral acceptance and fails visibly for incomplete or failing coverage.
- Put note creation and refresh directly into proto's existing checkpoint, with one shared note format and no duplicate task list.
- Distinguish a missing note from an unrecoverable requirement: reconstruct from authoritative artifacts when possible; ask once when necessary instead of inventing product behavior.
- Reconcile contract approval, PR-description updates, and post-merge note completion across existing workflows. Preserve explicit approval for reviewer replies and other currently gated external actions.
- Reuse the resolved verification commands and prior grounded findings across skills; carry only current state and non-reconstructible rationale.
- Extend the disposable benchmark with a small set of independently checked transition scenarios, explicit plain-language routing, and limited cross-model runs. Keep failures and evaluate correctness before efficiency.

## Capabilities

### New Capabilities

- `harness-continuity`: Portable project instructions, recoverable contracts, concrete checkpoints, consistent transition ownership, and evidence-backed completion across existing skills.
- `harness-evaluation`: Bounded scenario evaluation of routing, continuation, missing requirements, and lifecycle outcomes across model configurations.

### Modified Capabilities

None. This repository has no existing main specs; these deltas document intended behavior and are not synced or archived until the implementation PR merges.

## Impact

Instruction changes target the new root AGENTS.md, agents/skills/harness-boostrap/SKILL.md, agents/AGENTS.md, and agents/skills/{proto,yolo,feedback,address-review,land}/SKILL.md. Benchmark changes target bench/measure, bench/test_measure.py, bench/README.md, and small scenario fixtures or findings under bench/. Existing directory links already expose shared skills (macos.sh:298-301 and linux.sh:338-341). No dependency, CI, auth, installer, production-service, or global-ignore changes are intended.

Continue on feat/skill-based-agent-harness. Planning does not promote the prototype or authorize implementation during this turn. On approval, yolo consumes these artifacts, implements and verifies the accumulated work on the same branch, and leaves its PR open for human review. Preserve the unrelated edits to claude/settings.json and agents/skills/tldraw-offline/SKILL.md.
