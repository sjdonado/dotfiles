---
description: Plan a non-trivial change — understand the system, clarify once if needed, produce a coherent plan (no implementation)
---
Plan: $@

Load and follow the `plan-mode` skill — system-aware planning, smallest coherent solution, think broadly implement narrowly.

1. Understand first. Investigate the codebase and the actual problem before proposing anything. What already exists, the real requirement, the surrounding system (data flow, state ownership, interfaces, lifecycle, failure modes).

2. Clarify only if requirements are ambiguous or underspecified. Ask specific questions and STOP. Otherwise proceed straight to the plan.

3. Produce the plan per plan-mode: the smallest change that stays coherent with the architecture, where it belongs, and why. Cite relevant code as `path:line`.

Do NOT implement — plan only. No edits, no commits.

Use subagents only if the task genuinely benefits (large recon, parallel work); otherwise do it directly.
