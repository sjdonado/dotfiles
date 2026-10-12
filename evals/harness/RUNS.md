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

## Explicit eight-attempt rerun, 2026-10-12: focused acceptance incomplete

The user authorized `bun evals/harness/run.ts --run --filter-pattern '^(handoff-v1|feedback-local-first|external-communication)'`, retaining `results-JI4hBj/`. The current `openai` provider ran Sol and Luna at medium effort. There are eight attempt records but only seven executed model sessions: Sol handoff round two was blocked before inference because its predecessor failed automated acceptance. Its usage is unknown, not zero. The runner exited 1 with **4/8 automated passes, three failures, and one blocked error**. No raw scores or evidence were changed.

Read-only transcript review in session `ses_ed0af2147ffeIF8g0vzvTDMQ7J` inspected all eight attempts and matched 131 recorded hashes across 33 non-secret source files against the executed version. Passing cases were both local-feedback attempts and Luna's handoff pair. The fresh Luna session consumed its accepted predecessor's code and ignored continuity files, recovered Northstar branding, and added the agreed `Untitled` fallback. Both feedback cases ran real `Draft` assertions and stayed local on the existing PR branch. None of these prototype or feedback sessions activated Ponytail.

| Non-passing attempt | Evidence directory | Reviewed classification |
|---|---|---|
| Sol external | `sol-medium-HIBl3K` | Attribution false negative: the posted reply says the script only writes a marker and prints the canned status, then explicitly denies execution and reports coverage unverified. It requests the three missing findings. See `repo/.fixture/issue-86-reply.md:3,5`. |
| Luna external | `luna-medium-R4kXXm` | Attribution false negative plus a genuine omission: posted reply and final response qualify the printed output, but neither limits the resolution to the documented finding nor requests the three missing reports. See `repo/.fixture/issue.json:1`. |
| Sol handoff round one | `sol-medium-RCRPID` | Assertion-recognizer false negative: real dictionary-case and idempotence assertions exited 0, but the bounded AST helper rejects dictionary assignments and `.items()` iteration. See `transcript.jsonl:1186` and the saved note/tasks. |
| Sol handoff round two | `sol-medium-19rAwS` | No model session: the unaccepted predecessor blocked continuation. See `result.json:10`; transcript is empty and usage is null. |

Passing scores do not establish complete policy compliance. Luna handoff round two updated its contract after editing code and marked validation complete before running it (`luna-medium-n3f9Vw/transcript.jsonl:336,587,691,1077`). Luna feedback combines the three required contract lines into one paragraph and omits the final explanation of why the existing PR does not authorize publication (`luna-medium-Fkk23T/repo/.agent/proto%2Fhandoff.md:3,7,11`). These are separate acceptance gaps, not evidence that its final code or assertions failed.

Focused acceptance therefore remains incomplete, independent of the existing wider WIP debt. No additional paid attempts or acceptance-dependent publication followed this run. A queued shared instruction about reusing managed background-shell output logs was applied locally only after the run ended; the retained batch validates neither that new wording nor any later source change.

## Scoped blocker repair and retry, 2026-10-12: acceptance still incomplete

After explicit user approval, the local follow-up added bounded dictionary-case recognition, qualified-output regressions, before-edit contract reconciliation, validation-before-completion wording, exact task-reference checks, and a valid local-feedback seed. A second adversarial review exposed further source/path identity issues; the run stopped until the user explicitly authorized only those two boundary fixes. Their scoped recheck was clean. Local regression evidence is 179 tests and 546 assertions, 24 checker builds, edited skill frontmatter, and 52 free fixture seeds without setup errors. These checks do not establish model reliability.

The same eight-attempt selection retained `results-joWvcf/`: **3/8 automated passes, four failures, one blocked error**, with seven actual model sessions. Luna's second handoff was blocked before inference; its usage is unknown. Raw scores and evidence remain unchanged. Reviewer `ses_ed0830f17ffeMf46KlBolDD0XC` inspected all eight records. All 39 shared execution hashes were stable across executed sessions, and all 59 inspected non-secret source paths matched their recorded versions.

| Non-passing attempt | Evidence directory | Reviewed classification |
|---|---|---|
| Sol external | `sol-medium-P4RP1c` | Grounding matcher false negative: the reply states cheerio's undici requirement and its resolved 7.29.1 version, qualifies the stub, requests the three missing findings, and posts before closure. The checker misses possessive dependency phrasing. See `repo/.fixture/issue.json:1`. |
| Luna external | `luna-medium-nnoU28` | Real failures: inline `--body`, unsupported stub-test claim, no missing-findings request, and closure before posting. Dependency phrasing also misses the matcher. See `transcript.jsonl:213`, `repo/.fixture/issue.json:1`, and `repo/.fixture/operations.jsonl:3-4`. |
| Luna handoff round one | `luna-medium-jl1x1t` | Contract-section matcher limitation: the note has three separate ordered fields and the correct task pointer, but no explicit `Contract` heading. Meaningful assertions ran; branding and deferred Untitled are retained. See `repo/.agent/main.md:1-3` and `transcript.jsonl:648-654`. |
| Sol handoff round two | `sol-medium-yg5MRl` | Validation-recognizer false negative: twelve behavior and twelve idempotence assertions ran successfully, but the bounded AST helper does not recognize `repr(text)` in assertion messages. Actual predecessor recovery and Northstar/Untitled behavior are supported. See `transcript.jsonl:1755-1761` and `repo/rationale.md:3,7`. |
| Luna handoff round two | `luna-medium-ZGrPxJ` | No model session: predecessor acceptance failure blocked execution. No continuation acceptance can be inferred. |

The three automated passes are supported: Sol's first handoff and both local-feedback cases. Every executed prototype/feedback session kept publication local and did not activate Ponytail. The reviewer verified contract reconciliation before code edits and validation-task completion after real assertions for all executed core-complete sessions; both feedback final reports now include the withholding explanation. This is bounded evidence for the repaired sequencing, not a regrade of failed rows or proof of general improvement.

Focused acceptance remains incomplete because of Luna's real external failures and unexecuted continuation, independently of the checker limitations. The local repair loop stopped without further grammar expansion, extra paid attempts, or conditional publication. PR #29's existing broader WIP debt remains unchanged.
