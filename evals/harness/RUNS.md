# Paid eval matrix, 2026-10-08

Full matrix: 24 scenarios × sol-medium + luna-medium = 48 sessions, `bun evals/harness/run.ts --run`. Evidence (prompts, transcripts, results) retained in ignored `evals/harness/results-x01xOi/`. No reset, no cherry-picking; every attempt counts.

## Historical automated tally: 26/48 (not a validated quality score)

The table preserves the original automated outcomes and failure labels. The October 10 audit found fixture and checker defects behind several labels below. An invalid attribution is not a retrospective pass. Raw evidence under `results-x01xOi/` remains unchanged; do not use this tally to rank model quality or infer a Ponytail effect.

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

The original claim that every failure was model behavior was incorrect. The audit in session `ses_ed935905bffeoqXDa2A5Ec72is` identified six branch-note/task failure cells whose checkers expected `proto/handoff` while execution used `main`, six feedback cells seeded on `main` without the existing PR branch, and two handoff round-two cells seeded independently without the preceding agreement. These 14 failure attributions are invalid, not proven passes. Remaining outcomes still need semantic review; the latest batch has no retained review records. Printed mock verification claims also require an independent reporting check.

## Corrective priorities

1. Resolve continuation paths from the seeded branch rather than changing model instructions to compensate for incorrect checks.
2. Seed feedback on its existing PR head. A correct ownership stop is not a routing failure.
3. Pass actual round-one artifacts into a fresh handoff session. Independent fixtures do not establish continuity.
4. Reject skipped or failure-masked validation and unsupported test claims with positive and negative regression cases.
5. Review bounded transcript evidence for the remaining external, workspace, and model-specific outcomes before attributing cause.

Local evaluator repairs and deterministic regressions do not validate model behavior. Fresh paid runs and transcript review remain required before reporting behavioral acceptance or comparing model reliability.

## Bounded historical transcript review, 2026-10-11

Nine labelled failure cells were reviewed against their retained seed artifacts and historical checker hashes, without changing raw evidence. These findings do not regrade the full matrix or establish a Ponytail effect:

- Sol's external reply (`sol-medium-3u9ewQ/transcript.jsonl:705`) gives the resolved Undici version, transitive range, and relevant citations, asks for the missing issue details, and states that `check.py` is not independent test verification. The checker incorrectly required a WebSocket mention and `src/client.ts` citation even though that file only trims HTML. The corrected checker requires the dependency evidence in `package.json` and `bun.lock` instead.
- Luna's external reply (`luna-medium-JGpugI/transcript.jsonl:280,493`) promotes printed mock output into typecheck, lint, and 125-test evidence and omits the issue-title discrepancy. That is a genuine reporting failure, distinct from the checker defect. The new attribution guard rejects those unsupported claims in both the posted reply and final response.
- Both workspace-requested sessions inherited `HERDR_ENV=1` while their Herdr stub deliberately failed (`sol-medium-0LrrT4/transcript.jsonl:174,440` and `luna-medium-bgioIm/transcript.jsonl:90,200`). The checker demanded the in-place fallback reserved for an unset variable. Disposable Pi sessions now remove the inherited workspace marker so the seeded premise matches that fallback.
- Luna's bounded report (`luna-medium-0VQsh5/transcript.jsonl:1497`) names the branch and checkout in adjacent sentences. The historical same-sentence matcher produced a false failure; it is not evidence that the work was left in another checkout. Bounded and workspace checks now share a matcher that accepts an unambiguous current-worktree report and does not split dotted checkout paths into separate sentences.
- Both open-shape sessions created `.agent/main.tasks.md` and both phase implementation sessions created `.agent/main.md`, while checkers read fixed `proto/handoff` paths. The corrected checks derive paths from the seed branch. The open-shape prompt also did not prescribe casing or blank-input behavior, so its runnable-slice check no longer imposes hidden product decisions. Transcript review still judges the chosen prototype against the user's open request.

Evidence paths above are relative to ignored `evals/harness/results-x01xOi/`. Historical source was checked against retained hashes at commits `0ef7f9e6c1b150e24bff9725a11474786b604074` and `ccaa212de89208fd8a762f70c6d513c8fde389ec`. Those sessions used Pi 1.0.2 and Sol/Luna medium on October 8; new attempts must retain their own runtime versions and hashes.

## Focused follow-up, 2026-10-11/12: behavioral acceptance incomplete

The user explicitly authorized WIP publication with remaining paid acceptance debt after selecting "Fix help and publish WIP". Local checks are green, but this is not a validated harness release or a model-quality comparison.

The final retained OpenAI-provider batch is `results-dL18ih/`: 20 sessions, ten scenarios across Sol and Luna medium, with **13 automated passes, six failures, and one execution error**. Sol is 8/10 automated passes; Luna is 5/10, four failures, and one error. Every final transcript and retained fixture was reviewed. Original scores remain unchanged:

| Non-passing row | Evidence directory | Reviewed classification |
|---|---|---|
| Sol external | `sol-medium-y6olbz` | Matcher false negative: quoted printed status and explicit execution denial span three sentences. Dependency evidence and missing-finding request are grounded; coverage remains unverified. |
| Luna external | `luna-medium-9dKP0E` | Real reporting failure: omits the print-only caveat and undocumented findings; dependency facts are correct but the transitive explanation is incomplete. |
| Sol open-shape | `sol-medium-VuxlDY` | AST recognizer rejects a valid non-string test loop containing a dictionary literal; real assertions ran and the local prototype is sound. |
| Luna workspace | `luna-medium-Zgr44o` | Placement is correct; "checked out in the current repository" misses the matcher and omits the concrete branch/path. |
| Luna address-review | `luna-medium-oMuCOC` | Correct local repair and tests, but no PR-state inspection and an incomplete proposed external-action batch. |
| Luna Reviewer B | `luna-medium-DRARmj` | Did not read Ponytail and proposed unsupported separator-tokenization behavior. No writes occurred. |
| Luna explicit phase | `luna-medium-2hACKG` | Timed out at 300 seconds before implementation and validation completed; usage is unknown, not zero. |

The thirteen passing rows have real assertions, appropriate activation and meaningful saved state, and preserve the relevant local/publication boundaries. Both handoff pairs consume actual accepted predecessor artifacts and recover Northstar branding rationale. The final help-probe correction has deterministic regressions; no additional paid batch was run after that small correction.

The final native preview probes, `results-native-preview-1791728694288-gpt-6.1-sol/` and `results-native-preview-1791728656043-gpt-6-luna/`, both pass and were semantically reviewed against recorded source hashes. They show native `background: true`, a registered running shell ID, actual HTTP readiness before handoff, independent post-client registry/response evidence, and verified owned-shell cleanup. A Sol launch with a misspelled log directory failed before execution and was corrected; it is not counted as a model attempt.

Earlier attempts remain retained: `results-83IwoD/` and `results-5LTJtQ/` were blocked by the old `openai-codex` credential route; `results-0nHH4w/` established that the requested `openai` provider works but exposed a Reviewer B language-matcher false negative; `results-l5wBx2/` was 9/20 automated passes; `results-oGe9IR/` was 7/8. Earlier native probes also exposed checker false negatives for Code Mode fetch and silent Python HTTP assertions. These failed attempts were not deleted or silently regraded. Differences in provider, runtime, instructions and checks prevent attributing score changes to Ponytail alone. No token savings or general model-reliability improvement is claimed.
