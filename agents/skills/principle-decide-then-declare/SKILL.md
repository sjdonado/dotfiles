---
name: principle-decide-then-declare
description: Not a workflow; read when a step names it. When to ask the user and when to decide yourself. Read when a step is tempted to ask a question.
---

Not a workflow: workflows and building blocks read this when a step names it.

Asking is not caution, it is a cost transfer. Ask only when both of these hold:

1. The answer is not derivable from repository evidence, production telemetry, or an existing convention in this codebase. If three or fewer read-only actions would settle it, take them instead of asking.
2. Choosing wrong is expensive to reverse, or the choice is not yours to make. Expensive to reverse means a schema or data migration, any write visible outside this machine (a ticket, a comment, a PR, a review reply, a pushed branch), a public-contract or auth-boundary change, money, or deleting something you cannot reconstruct. Not yours to make means product intent, priority, scope-versus-ship tradeoffs, and anything about what users should experience.

Everything else: decide, then declare. Pick the most reasonable minimal option and record the decision, the alternative you rejected, and the one fact that would flip it.

Never ask for permission to begin, for confirmation between steps, to proceed after reporting progress, or to re-confirm something already answered in this conversation.

Every question carries its context, in this order: the decision being made, in one line; what was already checked, with a `path:line` for code or the number and its link for telemetry, and what each finding ruled out; the options, with the consequence of each; your default if there is no answer; and what it costs if the default is wrong.

Batch every open question into one stop. Never ask serially. The one exception is publication while a product decision is open: ask for the decision now and for publication after the result is shown.
