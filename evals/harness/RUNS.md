# Paid eval matrix, 2026-10-08

Full matrix: 24 scenarios × sol-medium + luna-medium = 48 sessions, `bun evals/harness/run.ts --run`. Evidence (prompts, transcripts, results) retained in ignored `evals/harness/results-x01xOi/`. No reset, no cherry-picking; every attempt counts.

## Tally: 26/48

| Scenario | sol | luna |
|---|---|---|
| route-bounded | pass | fail (missing checkout sentence only) |
| gate-mixed-scope | pass | pass |
| recoverable | pass | pass |
| external-communication | fail (ungrounded reply) | fail (ungrounded reply) |
| handoff-v1 round 1 | fail (no branch note) | fail (no branch note) |
| handoff-v1 round 2 | fail (no-op) | fail (no-op) |
| unrecoverable | pass | pass |
| read-only | pass | pass |
| feedback | fail (no-op) | fail (no-op) |
| land-open | pass | pass |
| land-merged | pass | pass |
| bootstrap-audit | pass | pass |
| bootstrap-setup round 1 | pass | pass |
| bootstrap-setup round 2 | pass | fail (rewrote instructions) |
| route-open-shape | fail (no task list) | fail (no task list, broke blank behavior) |
| gate-self-authored | pass | fail (gap unnamed) |
| gate-precedent | pass | fail (gap unnamed, README unfixed) |
| feedback-local-first | fail (no-op) | fail (no-op) |
| feedback-approved-batch | fail (no-op) | fail (no-op) |
| workspace-default | pass | pass |
| workspace-requested | fail (talked, built nothing) | fail (talked, built nothing) |
| phase round 1 | pass | pass |
| phase round 2 | fail (code right, note missing) | fail (code right, note missing) |
| phase round 3 | pass | pass |

## Spend

sol: 24 sessions, ~2.1M tokens (1.7M cached), ~17 min wall. luna: 24 sessions, ~3.0M tokens (2.4M cached), ~10 min wall. Zero runner errors.

## Oracle verdict

No false alarms found. Every failure traces to model behavior, not check logic. The ported oracles (including the `label('   ')` fidelity fix and the seeded-note untracking) held under live runs.

## Fix backlog (not started)

1. **Continuity ignored**: handoff round 1, phase round 2, route-open-shape. Agents implement correctly but skip the branch note / task list. Candidate: strengthen continuity wording; verify against a rerun.
2. **Feedback rounds are no-ops** on both models (feedback, local-first, approved-batch): no code change, no PR edit. Transcripts need review before prescribing a fix; possible prompt-shape or skill-routing cause.
3. **External replies ungrounded** on both models: issue closed with no versions, relation, or file citations. Same: review transcripts first.
4. **workspace-requested builds nothing** on both models: agents discuss herdr instead of acting. Possible missing substitute discovery or overcautious gating.
5. **handoff round 2 total failure** on both models: no behavior change, no rationale, no validation run. Needs transcript review.
6. **Luna-only slips**: route-bounded checkout sentence, setup round 2 instruction rewrite, gate gap naming. Smaller prompt-following gaps; rerun after the above.
