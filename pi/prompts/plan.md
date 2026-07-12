---
description: Plan a non-trivial change — understand the system, clarify once if needed, produce a coherent plan (no implementation)
---
Plan: $@

Load and follow the `plan-mode` skill — system-aware planning, smallest coherent solution, think broadly implement narrowly.

0. Establish the input. The thing to plan may come from several sources — use whichever applies:
   - A prior `grill-me` (`/grilling`) session in this conversation — treat the sharpened problem/approach it produced as the requirement. Do not re-litigate what grilling already settled.
   - A prior `/ask` answer in this conversation — the question and its resolution frame the change.
   - A prior `/triage` output — its Findings, Options, and Recommendation are your starting point; plan the recommended option unless told otherwise.
   - A Linear ticket or a plain task passed directly in `$@`.
   If `$@` is empty, take the input from the most recent of the above in history. If sources conflict or none is clear, ask which to plan and STOP.

1. Understand first. Investigate the codebase and the actual problem before proposing anything. What already exists, the real requirement, the surrounding system (data flow, state ownership, interfaces, lifecycle, failure modes).

2. Clarify only if requirements are ambiguous or underspecified. Ask specific questions and STOP. Otherwise proceed straight to the plan.

3. Produce the plan per plan-mode: the smallest change that stays coherent with the architecture, where it belongs, and why. Cite relevant code as `path:line`.

Do NOT implement — plan only. No edits, no commits.

Use subagents only if the task genuinely benefits (large recon, parallel work); otherwise do it directly.
