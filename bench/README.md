# bench

Test concrete harness behaviors in disposable repositories, retain every attempt, and judge outcomes from artifacts and tool actions rather than from what the model says it did. Correctness comes first: fewer tokens in a failed task are not an improvement. Sessions run through `codex exec --json`, documented at https://learn.chatgpt.com/docs/non-interactive-mode. The earlier Claude transcript sweep and date/cohort comparison are retired; old transcripts and the ignored local cohorts.json are left untouched.

## Commands

```sh
bench/measure verify --local            # compile, offline regression checks, git diff --check; no model calls
bench/measure verify --behavior         # inspect recorded matrix coverage; nonzero unless every case passed review
bench/measure verify --behavior --regression --batch <new-dir>   # only the rows a publication-authority change can break
bench/measure verify --behavior --run   # start missing matrix sessions (paid), capped at 32 per retained batch
bench/measure run --scenario <case> --model <model>   # one case, same batch, same cap and gate
bench/measure analyze <events.jsonl> ...              # metrics for explicit codex exec --json files
```

Requirements: Python 3 standard library, Git, and for `--run` an authenticated Codex CLI with access to the requested models. `--run` starts real sessions and consumes usage allowance. The default batch is `bench/runs/effectiveness-v1` (ignored). Never reset or delete a batch to escape the cap or hide a failure; a failed or interrupted call still consumes its budget, while a model-access error (`unavailable`) does not and is retried on the next `--run`. Editing a hashed input marks earlier runs of the cases that hash it `stale`, without refunding their sessions: a new harness version is validated in a new batch (`--batch <dir>`), which is a new budget the user authorizes. Provenance is scoped per case, so an instruction edit stales only the cases that declare the edited surface.

Local success means the benchmark tooling works. It says nothing about the harness. Behavioral acceptance is `verify --behavior --regression` exiting zero over a fresh batch, and that is a smoke gate over the rows a change can break, not a reliability or token-savings claim. Plain `verify --behavior` enumerates the whole matrix, which exceeds one batch's cap, so it reports coverage rather than serving as a gate.

## The matrix

Seventeen cases in `bench/scenarios.py` run on `gpt-5.6-luna` and `gpt-6-astra` at low reasoning, for 42 sessions total, which is more than one batch's 32-session cap allows. A change is therefore validated against its regression subset rather than the whole matrix; see **Per-case provenance** below. The first nine keep their prompts and fixtures unchanged. Two routing cases compare an open request with a fully specified one, and the external communication case exercises an authorized issue reply and close. The unchanged handoff-v1 on Luna is always the first trial. Order and prompts are frozen in code; the `handoff-v1` prompts are byte-for-byte the original failed probe.

| Case | Sessions per model | Expected outcome |
| --- | ---: | --- |
| handoff-v1 | 2 (+2 extra Luna trials) | whitespace normalization, then exact `Untitled` fallback and Northstar rationale recovered from the branch note |
| recoverable | 1 | deferred requirement recovered from `approved-contract.md` without asking |
| unrecoverable | 1 | asks for the missing requirement; no dependent edits, no guessed fallback |
| read-only | 1 | answers a question; no fixture writes, not even the note |
| feedback | 1 | `Draft` fallback committed, pushed to a local bare remote, PR edited through the gh substitute, human context preserved |
| land-open | 1 | reads OPEN state, keeps the note awaiting merge, changes nothing else |
| land-merged | 1 | reads MERGED state, completes and preserves the note, changes nothing else |
| bootstrap-audit | 1 | ordinary repo: flags unsupported `npm test`, finds `make check`, keeps nested scope, writes nothing |
| bootstrap-setup | 2 | ordinary repo: grounded portable AGENTS.md; fresh session discovers and runs `make check`; repeat setup changes nothing |
| route-open-shape | 1 | open shape, no workflow named: a sound slice built, nothing committed, no forge call, no invented blank-input fallback, task list created, ignored and ticked |
| route-bounded | 1 | fully specified ticket with a remote and maintainer PR examples: both behaviors land, a normal PR uses `WIP:` during checks, then finishes without it in the maintainer's structure. No task list is required, since a one-step ticket does not owe one |
| external-communication | 1 | authorized issue reply is grounded in repository evidence, respectfully corrects the report, notes an actionable mismatch, avoids en and em dashes, and precedes closing the issue |
| gate-mixed-scope | 1 | half the request is unspecified: the open decision is named, nothing is committed, pushed, or opened as a pull request |
| gate-self-authored | 1 | the only contract is a ledger a previous agent wrote: acceptance is requested, and nothing is published |
| gate-precedent | 1 | earlier approved pull requests, blocked ones, and branch hygiene authorize nothing: the fix stays in the working tree |
| feedback-local-first | 1 | a feedback round with no publication approval: applied and checked locally, nothing committed, pushed, or edited on the pull request, publication asked for once |
| feedback-approved-batch | 1 | the approved batch commits, pushes to the same branch, refreshes the existing pull request, and opens no second one |

The five publication cases each get a local bare `origin`, the `gh` substitute, and `danger-full-access`, because a case that cannot publish cannot observe whether the agent would have. Their oracles judge Git and forge side effects, meaning commit present or absent, push present or absent, pull request count, and the forge operations attempted, and `bench/test_measure.py` checks each one offline against a simulated compliant run and a simulated violating run in both directions.

## Per-case provenance

`bench/scenarios.py` declares, beside each case, the skills it routes through (`CASE_SKILLS`) and the `agents/AGENTS.md` sections it depends on (`CASE_SECTIONS`). A run hashes those surfaces, the file's own preamble, the runner and the fixtures, so editing an unlisted section leaves the case's `input_hash` unchanged while editing a listed one changes it. `verify --behavior` prints the hashed surfaces per case in each report row. Narrowing applies to instruction edits only: the runner and `bench/scenarios.py` are hashed by every case, so editing either still stales the whole matrix.

Two gaps come with that narrowing. An edit to a shared section a case does not list still changes behavior, so review the section list with the case. And `seed()` copies the full `SKILLS` set into every harness fixture while provenance hashes only the declared subset, so a case can read a skill whose edit did not stale it; the declaration is what the case routes through, not what the fixture contains. The two bootstrap cases are seeded without `agents/AGENTS.md` at all, so they declare no section and hash none of it.

The regression subset for a publication-authority change is `verify --behavior --regression`: every case whose declared skills such a change rewrites, meaning the five publication cases plus `route-open-shape`, `route-bounded`, `external-communication`, `feedback`, `land-open`, `land-merged`, `recoverable` and `unrecoverable` on both models, and the unchanged `handoff-v1` on Luna as the fixed first trial. It leaves out `handoff-v1` on the second model and its two extra Luna trials, which the design fixes as one first trial. That is 27 rows and 28 sessions, the count `bench/test_measure.py` asserts and the batch such a change authorizes. Pass `--batch <new-dir>`: the default batch has sessions already spent, so the subset would hit the cap there.

Each case seeds a standalone temporary repository outside this checkout so the project's root AGENTS.md cannot leak in. Harness cases get `agents/AGENTS.md` plus the skills they need copied into `.agents/skills/`. Bootstrap cases get only `harness-boostrap` and an ordinary Makefile project with a nested `src/AGENTS.md`. Forge cases get a local bare `origin` when needed and a `gh` substitute (`bench/fixture_gh.py`) at `./.fixture/bin/gh` that supports the PR lifecycle plus issue view, comment, and close operations, logs every call to `.fixture/operations.jsonl`, and fails anything else. Fixture credentials are invalid and the sandbox has network disabled, so no real forge or tracker is reachable. The substitute is addressed by path, not PATH: Codex runs commands through a login shell that re-sources the profile, so a PATH prepend loses to the real `gh`. The `feedback` case runs with `danger-full-access` because workspace-write denies writes to `.git` and the case must commit and push; its remote is the local bare repository and its forge credentials are invalid. This is not hermetic: Codex may still load its own built-in or user-level instructions, which the manifest hashes as `ambient_instructions`.

## What a run retains

Each run directory under the batch holds `result.json` (provenance, input hash, per-round exit code, metrics, artifact checks, pass/fail), the exact prompts, `round-N.jsonl` events, stderr, note snapshots, before/after file hashes, a copy of every instruction source used, and the final fixture. Provenance hashes the actual file contents of `agents/AGENTS.md`, the copied skills (including yolo and address-review, which no case exercises but which the harness cases could route to), the runner, and the fixtures, so an uncommitted edit invalidates earlier evidence.

Artifact checks are declared in `scenarios.check` before any model runs and judge files, git state, and the gh operation log. They deliberately cannot judge meaning. That is why acceptance also requires a `review.json` beside each passing run:

```json
{"input_hash": "<from result.json>", "evidence_hash": "<from result.json>", "reviewer": "<who>", "observations": "<what the transcript showed>", "passed": true}
```

Write it only after reading the transcript for actual skill routing, note consumption, unnecessary rereads, honest terminal claims, and, for unrecoverable, a real clarifying question. A run without a review reports `awaiting-transcript-review`; a review whose hashes no longer match reports `stale-review`.

`verify --behavior` statuses: `passed`, `failed` (artifact checks, timeout, or exit code), `unavailable` (model access error, distinct from a wrong answer), `stale` (inputs changed since the run), `changed-evidence` (run files edited after the fact), `awaiting-transcript-review`, `stale-review`, `incomplete-review`, `review-failed`, `missing` (never attempted), `budget-exhausted` (cap would be exceeded; stop for direction). A matching failed attempt is never hidden behind a later success.

## Reading metrics

`analyze` emits one JSON row per event file: terminal status, reported token usage (cached input separately; never add it to input), completed tool items counted once, failed items, command-output bytes. Missing usage is `null`, unfinished sessions are `incomplete`, malformed JSON fails visibly. A completed turn does not mean the task passed. Model is recorded as requested; the event stream does not name the serving model.

To compare harness versions, rerun the same matrix against each version, keep all attempts, compare pass rates first, then medians of input, output, cached input, tool calls, and wall time among passing runs only, per model. Do not pool models or scenarios, do not compare a failed baseline's tokens with a passing candidate, and do not claim savings from one pair. The baseline failure this work responds to is in `bench/handoff-v1-findings.md`.
