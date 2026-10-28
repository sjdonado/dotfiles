---
name: feedback
description: Apply local follow-up changes with appropriate checks. When publication is requested, push the scoped changes and refresh the existing PR description.
---

Apply the requested feedback where the task already lives. A PR identifies the branch; its existence does not select a review, delivery mode or publication gate. When the user later requests publication, use open-pr to push only the authorized delta and refresh the existing PR description to match it, preserving human context and unrelated staged work.

1. Inspect the requested behavior and relevant diff. Preserve unrelated edits and settled requirements unless the user changes them.
2. Resolve routine details yourself; ask only about a consequential ambiguity you cannot resolve from the repository (principle-decide-then-declare).
3. Implement the change and verify its behavior (principle-prove-it-works and principle-test-agreed-decisions). Honor an explicit request to defer checks, and report what remains unverified.
4. Use agent-review only for a requested review or a concrete concern that needs independent inspection. Choose delegation by its benefit (principle-delegate-down-a-tier).
5. Report the changes, checks and remaining limitations. Publish through open-pr only when the user's authorization covers this batch; otherwise leave it local without a publication prompt.

For work that needs continuity, update its existing note or task list (principle-state-outlives-the-session). Do not introduce a ledger for a small change or require a declaration that feedback is finished.
