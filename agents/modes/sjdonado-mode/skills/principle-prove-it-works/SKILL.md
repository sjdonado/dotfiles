---
name: principle-prove-it-works
description: Guidance for staged verification, evidence labels, and completion claims. Read before checking work or claiming an outcome.
---

Choose evidence for the claim and its failure modes. Resolve required checks from repository instructions, the declared task runner, then repository evidence. Project-mandated gates remain mandatory at the time the project requires them; a mode cannot waive them.

## Verification stages

- Investigation or review: trace the actual artifact, callers, and failure paths. Support findings with evidence and distinguish inferences. A read-only request permits no source changes.
- Prototype or active iteration: run the cheapest meaningful check that makes the promised slice usable and tests the assumption being explored. Defer expensive delivery checks while the design is changing unless a concrete risk or project rule requires them now. Report ready to try, the demonstrated behavior, and deferred checks; do not report fixed or production-ready.
- Delivery or a claimed fix: check the final accumulated diff against settled requirements. Run required project checks and exercise changed behavior and relevant failure paths on the surface where they occur. Repeat a bug's original reproduction after the fix; compare a refactor with its pinned baseline. Check affected consumers of shared code. Compilation or a mocked demo alone does not prove runtime correctness.

A follow-up continues the current stage unless the user changes the outcome. Reuse evidence while its relevant inputs and environment remain unchanged. After an edit, invalidate affected results, including results for changed shared dependencies. At delivery, close every deferred check needed for the promised outcome; do not rerun unaffected checks just because another turn ended.

## Evidence and stopping

Keep one verification record in the existing task state when useful, or in the final report for a small task. Each claim has a label:

- Executed: observed on the actual runtime surface; name the command or interaction, environment, build, and result.
- Static: parsing, type checks, lint, unit checks, or source inspection; state what that establishes.
- Unverified: pending, deferred, unavailable, or inconclusive; name the exact missing check or prerequisite.

Inspect exit status and assertions. Keep a long-running check in the session that started it. Fix failures introduced by the task; distinguish unrelated failures with evidence. A worker's summary, a plausible patch, or a completed model turn is not proof. An unavailable capability cannot become a passing result. A failed check cannot be weakened to make delivery green.

Do not declare the requested outcome achieved while its required evidence is pending, failed, or unverified. Finish useful independent work, then report the precise gap and next action. For an intentionally limited prototype, deferred delivery checks are compatible with ready to try, never with ready for review.

Publication is separately authorized. An opened-PR request ends after required local gates, creation or refresh, and truthful reporting of pending remote checks. A green-PR request additionally requires required remote checks and mergeability; use the host watcher while pending. Neither outcome permits merging.

For harness changes, follow the project's selected manual checks. State the expected decision before each attempt and inspect actual actions and artifacts. Parsing establishes structure only; one successful session does not establish reliability, performance parity, or efficiency.
