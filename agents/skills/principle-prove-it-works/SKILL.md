---
name: principle-prove-it-works
description: Not a workflow; read when a step names it. The oracle ladder that makes "done" machine-checkable, and how harness changes are validated. Read before running checks or claiming work is done.
---

Not a workflow: workflows and building blocks read this when a step names it.

"Done" must be machine-checkable, not a judgement call. The ladder's shape is global; each repository supplies the commands. Cheapest first, each green before ascending:

1. type or compile check
2. lint
3. tests
4. build
5. push, open PR, remote required checks green

Resolve the commands in this order: the project's own `AGENTS.md` if it declares them; else the repository's declared task runner (a `justfile`, `Makefile`, or package-manifest target named `ci`, `check`, or similar); else infer them from the toolchain. Prefer a variant that narrows work to what changed. Record the resolved ladder in the branch note, so later passes do not re-derive it and a wrong inference is visible.

Run each check in its own shell call, without unrelated Git or file housekeeping or failure masking. For a long-running background check, wait for its completion notification and inspect its own exit status before advancing. If only a compound call's final status is available, rerun the check alone.

When a change touches data, auth, concurrency, migration, or a public contract, also verify its failure behavior, compatibility and rollback where relevant.

Re-derive the failure list on every pass; never work from a stale one. The ladder adapts to what exists: no remote CI means it ends at the local rungs plus an open PR; no tests means a shorter ladder. A missing rung is skipped, never faked. Resolving review threads is not a rung.

Before reporting coverage from an unfamiliar check, inspect its implementation: printed or stubbed success messages do not establish that a check ran. Report coverage as unverified when its execution is not established.

**Harness changes.** Validate a harness change with a disposable session scenario that exercises the changed behavior, following the project's benchmark instructions. Declare the expected artifacts and assertions before running, retain prompts, versions, model settings, transcripts and results, and test continuation in a fresh session when continuity is involved. Judge correctness from artifacts and transcripts before comparing tokens or tool calls. Missing usage is unknown, never zero; a failed run is evidence, never silently discarded. One successful scenario is a smoke test, not proof of efficiency.
