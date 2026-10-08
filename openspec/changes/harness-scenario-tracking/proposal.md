# Proposal

## Why

Harness measurements currently require changing a Python scenario dispatcher as well as the runner. Define the first regression slice as JSON scenarios, reusable fixtures and small artifact assertions, with a minimal TypeScript runner that preserves evidence instead of growing another benchmark framework.

## What Changes

- Add `evals/harness/scenarios.json` with four initial cases: bounded PR flow, mixed-scope publication gate, recoverable continuation and grounded external communication.
- Copy current instruction sources into disposable fixtures and hash the execution inputs. Judge Git and forge actions from artifacts and operation logs, not claims in the final answer.
- Execute the same scenarios on `gpt-6.1-sol` and `gpt-6-luna` through the existing Pi CLI, using Bun and standard-library TypeScript without new dependencies or Pi updates.
- Retain exact prompts, model settings, CLI version, usage, timing, transcripts and artifacts for every attempt, including errors. Missing measurements remain unknown.
- Reconcile Ponytail and its code-writing callers with the implementation-only phase boundary. Add the smallest fresh-session phase-continuation case through the existing bench path.
- Record parity before retiring overlapping legacy rows. Keep non-overlapping Python cases and historical evidence; this PR is a first slice, not a full matrix port.

## Capabilities

### New Capabilities

- `harness-tracking`: declarative harness regression scenarios with expected tool and artifact assertions, runnable across harness versions and models.

### Modified Capabilities

None.

## Impact

- New: `evals/harness/` JSON configuration, fixtures, artifact checks, Bun runner and docs. Updated: Ponytail activation and its callers, plus an opt-in bench continuation case and offline tests. The shared publication contract remains unchanged.
- Dependency: existing Bun, Pi, Git and Python for the legacy comparison and fixture checks. No new packages or lockfiles. Paid calls require explicit execution and retained per-batch budgets.
- Excluded: unrelated Moshi configuration changes, Pi updates, MCP/code-mode rollout and Pi Durable exploration. Code mode targets daily Claude, Codex and OpenCode if revisited; Pi remains eval-only.
