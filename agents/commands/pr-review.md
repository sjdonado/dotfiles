---
description: Human-only entry point for an independent PR/MR review; never invoke from another workflow
argument-hint: "[PR/MR, mode, and optional context]"
---

<human_pr_review_invocation>
The current top-level human directly typed `/pr-review $ARGUMENTS`. This dedicated command wrapper is the only valid indirect entry into the `pr-review` workflow.
</human_pr_review_invocation>

<pr_review_instructions>
!`cat "$HOME/.config/opencode/skills/pr-review/SKILL.md"`
</pr_review_instructions>

Follow the embedded instructions. Do not reuse this invocation for retries, incremental passes, or review/fix loops. Every additional review requires the human to type `/pr-review` again.
