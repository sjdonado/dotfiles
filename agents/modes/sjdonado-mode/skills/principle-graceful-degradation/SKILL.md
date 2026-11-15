---
name: principle-graceful-degradation
description: Classify dependency failures and fallbacks while preserving user work, required safeguards and honest outcomes.
---

Before adding a fallback or error path, classify what failed and what the user's action requires:

- Fail closed when continuing could bypass authentication, authorization, billing controls or data integrity, or when a dependency is required for the action to succeed.
- Fail visibly for an irreversible external effect or an unknown completion state. Preserve the distinction between a confirmed rejection and a timeout that may already have produced the effect.
- Fail open only for an optional capability the action can succeed without. Continuing must preserve required safeguards and must not report more success than occurred.

Preserve input and work in progress. Defer disruptive reloads, updates and dialogs to a safe point. Retain a failed save only through the product's supported recovery path; do not silently lose it or invent a queue that cannot preserve its contract.

Never switch an outbound channel, sender or provider chosen by the user without their choice. When an outcome is unknown, check authoritative status before offering a retry or alternative, explain any remaining duplicate-effect risk, and apply principle-make-operations-idempotent before retrying.

Carry a classified cause and useful next action to the user-facing boundary instead of replacing every failure with a generic error. Make optional degradation quiet when the user cannot act on it. Emit bounded diagnostic reasons without secrets or private payloads; add monitoring proportionate to the affected path and the project's existing observability conventions.

Bound recovery by a retry budget, deadline or explicit escalation condition. Verify rejection, unknown completion, optional dependency loss and recovery for the paths changed. A degraded state must not silently become permanent or appear as complete success.
