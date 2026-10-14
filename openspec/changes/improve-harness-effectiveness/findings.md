# Findings

Behavioral evidence gathered for this change by the retired Python benchmark (`bench/measure`). The benchmark was removed, and its scenarios were replaced by the end-to-end YAML scenarios under `evals/scenarios/`, run by `evals/run.ts`. The raw runs under `bench/runs/` were never distributed. The two reports below are kept as historical evidence.

## First handoff probe

On 2026-09-08 at 05:28:32 UTC, handoff-v1 ran two fresh Codex CLI 0.153.4 sessions requesting gpt-5.6-luna with low reasoning. Source commit: 9f51334892a2e00e9ffbfe5df304963e7df3f3c8. AGENTS.md SHA-256: 5a48b28aa09b13a649a15aed3bf47396b433d05013c03a97aca4f2797caed7da. The ignored evidence directory is bench/runs/handoff-50hap931/, containing result.json, both JSONL transcripts, prompts, and the fixture. These local artifacts are not distributed with this report.

| Round | Artifact outcome | Input tokens | Cached input tokens | Output tokens | Completed tool items |
| --- | --- | ---: | ---: | ---: | ---: |
| 1 | Correct normalization; no durable note | 172013 | 125440 | 1170 | 5 |
| 2 | Wrong blank fallback; lost business rationale; no note | 241304 | 215808 | 1840 | 8 |

Usage comes from each transcript's turn.completed event; cached input is reported separately and must not be added to input as if disjoint. Tool items are completed command_execution and file_change events. This is a failure report, not a cost comparison.

Both sessions read proto and ponytail. Round 1 also read AGENTS.md and resolved the exclude path, but never created or updated the handoff note. Its code passed the independent assertions.

Round 2 tried to find the note, found none, and chose empty-string behavior instead of the deferred Untitled fallback. It replaced the specific Northstar branding rationale with a general argument about preserving capitalization. It reported the deferred behavior implemented even though the independent assertion failed. The runner retained both failed rounds and exited nonzero.

The tested handoff rule was insufficient in this attempt. Reading the relevant skills did not ensure that the note was written, and missing context led to an invented requirement. A next harness experiment should test a concrete checkpoint instruction in proto and a missing-contract rule on continuation, using the same scenario without changing its expected behavior. Neither fix has been made as part of this benchmark replacement.

This probe deliberately bypassed commits and external actions. It says nothing about PR/merge workflows, other models, or general token savings. The initial runner was still under development; subsequent parser robustness changes were tested offline against these same events, without rerunning or discarding the failure.

## Effectiveness matrix, batch v1 (stopped)

Batch `bench/runs/effectiveness-v1` started 2026-09-09 at 15:01:28 UTC on harness commit 7633958 plus the uncommitted repairs described in the PR, Codex CLI 0.153.4, low reasoning. Nine of 26 sessions ran before the operator stopped the matrix; one Astra handoff session was killed mid-round and counts as spent. All runs are retained locally and ignored. The batch is stale for acceptance: the fixture repairs it motivated change hashed inputs.

| Case | Model | Round | Artifact result | Input | Cached | Output | Tool items | Seconds |
| --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: |
| handoff-v1 | luna | 1 | note created, correct code; `/.agent/` not added to info/exclude | 214465 | 191488 | 1855 | 5 | 54 |
| handoff-v1 | luna | 2 | exact `Untitled` and Northstar rationale recovered from the note; same exclude miss | 143476 | 118528 | 1452 | 4 | 39 |
| recoverable | luna | 1 | pass | 215936 | 174080 | 2161 | 10 | 63 |
| unrecoverable | luna | 1 | pass: asked what blank input should return, no edits | 103222 | 82944 | 832 | 3 | 24 |
| read-only | luna | 1 | pass: explained empty string, no writes | 72107 | 55552 | 361 | 2 | 15 |
| feedback | luna | 1 | fixture blocked: sandbox denied `.git` writes; model reported it, claimed nothing | 342233 | 273408 | 2571 | 10 | 79 |
| land-open | luna | 1 | fixture blocked: real `gh` shadowed the substitute; model refused external contact, note intact | 149043 | 127488 | 1407 | 5 | 42 |
| land-merged | luna | 1 | pass: used `./.fixture/bin/gh`, completed note with merge evidence | 206535 | 183296 | 1522 | 7 | 52 |
| handoff-v1 | astra | 1 | killed by operator stop; no result | | | | | |

Usage comes from `turn.completed`; cached input is a subset of input. Cost is reported per outcome and is not a comparison: the baseline in the first handoff probe above failed the task, so its cheaper tokens bought nothing.

### What the harness repairs changed

The same byte-identical handoff-v1 prompts that lost the deferred requirement in the first probe now carry it across a fresh session: the note was written at the checkpoint, read on continuation, and the `Untitled` fallback and the Northstar branding rationale survived. The missing-contract case produced a clarifying question instead of an invented requirement. Read-only routing made no writes. These are one Luna trial each, a smoke result, not a reliability estimate; the two extra Luna handoff trials and every Astra case remain unrun.

### What still fails in the harness

Both handoff rounds skipped adding `/.agent/` to `info/exclude`, so the note was untracked but not ignored. The continuity rule states the step; the proto checkpoint text does not repeat it. Left unfixed in this batch so the matrix inputs stayed frozen; it is the one harness finding from these nine sessions.

### What failed in the fixtures, not the harness

Two fixture assumptions were wrong and are repaired in the runner:

- Codex runs shell commands through a login shell that re-sources the profile, so prepending `.fixture/bin` to PATH loses to the real `gh`. The land-merged session found `./.fixture/bin/gh` on its own; the land-open session did not, and correctly refused to contact an external host. Fixture guidance now names the substitute by path.
- Codex workspace-write denies writes to `.git`, so the feedback case could not commit or push. It now runs with `danger-full-access` against its local bare remote with invalid forge credentials. The `pushed` oracle also passed trivially on an unchanged HEAD and now requires a new commit.

Both failing sessions behaved as the harness intends under a blocked tool: they reported the block and made no false completion claim.

### Untested

gpt-6-astra on every case, repeated Luna handoff trials, both bootstrap cases, the feedback and land-open cases under the repaired fixtures, yolo and address-review end to end. No claim about other models, reliability, or token savings follows from this batch. A new batch with the repaired fixtures needs a fresh 26-session authorization.
