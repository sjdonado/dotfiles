---
name: principle-evidence-over-assertion
description: Not a workflow; read when a step names it. Ground claims in evidence gathered now, and check load-bearing runtime claims against telemetry. Read before stating a fact about behavior, impact, frequency, or coverage.
---

Not a workflow: workflows and building blocks read this when a step names it.

- Ground every factual claim in evidence gathered during the current session, repository state, tool output, or an authoritative source. State material inferences and uncertainty as such.
- Before claiming evidence is absent, inspect the relevant source-of-truth files and account for search filters that excluded them. An incomplete search means unverified, not absent.
- A claim about runtime behavior, impact, frequency, or performance is load-bearing only if being wrong about it changes the decision. Check load-bearing runtime claims against production telemetry through the `evidence` skill, or mark them explicitly unchecked.
- Never state a number without its source deep link and timeframe. Where a telemetry capability is not configured for a project, say so and move on; absence of data is never a reason to block or to invent one.
- When a plan brief, finding ledger, or OpenSpec change already grounded a fact with a `path:line` or a linked number, do not re-investigate it. Re-run only evidence marked refuted or unchecked, or that predates the most recent deploy.
