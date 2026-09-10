# First handoff probe

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
