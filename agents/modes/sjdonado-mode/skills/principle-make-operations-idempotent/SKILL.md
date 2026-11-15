---
name: principle-make-operations-idempotent
description: Design commands, jobs and external effects to recover safely from repeated execution or interruption.
---

Before adding a state-changing operation, answer what happens if it runs twice and if the previous attempt stopped after each mutation. Re-execution must converge on the intended state without duplicating effects or discarding unrelated work.

Read existing state and reconcile the difference from the goal. Do not infer success from an earlier attempt's intent. Use an atomic commit, a transaction, or a durable checkpoint appropriate to the boundary; ensure each committed step leaves enough evidence for recovery.

Make stale temporary files, locks and claimed jobs distinguishable from live ownership using evidence that remains valid after interruption. An old timestamp alone does not establish that another owner stopped. If ownership or completion cannot be established, stop the conflicting mutation and report the uncertainty.

For external effects, distinguish confirmed rejection from unknown completion. A timeout may follow an accepted request. Before retrying, use the operation's stable deduplication key or authoritative status lookup; if neither can establish safe repetition, report the unknown outcome instead of blindly resending. Keep any retry bounded.

Verify repeated execution and interruption at the meaningful commit boundaries in a disposable fixture or supported test environment. Inspect final state and effect count, not only return codes. Name any recovery path that remains unverified.
