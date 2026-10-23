---
name: principle-stop-at-the-rabbit-hole
description: Not a workflow; read when a step names it. When an autonomous run must stop and escalate, and what never justifies stopping. Read at the start of any run that works without the user.
---

Not a workflow: workflows and building blocks read this when a step names it.

Stop and escalate the moment any of these trips, regardless of the step:

- the same check has failed three times under three different fixes
- two consecutive attempts produced no new information
- the diff has grown past roughly three times the size the plan or request implied
- production evidence contradicts the premise of the work
- a second adversarial review round raises a new blocking finding
- the fix requires touching a surface outside the stated intent, or one of the surfaces the shared policy says escalate on first touch

On a trip, do not try a fourth thing. Report what was attempted, what each attempt disproved, the smallest next hypothesis, and what you need. A trip is information, not failure.

Do not escalate for: flaky or timed-out CI (re-run once; only a second failure counts as an attempt); lint or format failures (auto-fix them); a branch behind or mechanically conflicting with its base (rebase, resolve, continue; only a semantic conflict, where both sides changed the same logic, escalates); type errors in code you just wrote; dependency install, cache, or port collisions (re-run the project's provisioning); "I am not sure this design is optimal" (pick the minimal option, record it, continue).
