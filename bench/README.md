# bench

Test concrete harness behaviors in disposable repositories, retain every attempt, and judge outcomes from artifacts and tool actions rather than from what the model says it did. Correctness comes first: fewer tokens in a failed task are not an improvement. Sessions run through `codex exec --json`, documented at https://learn.chatgpt.com/docs/non-interactive-mode. The earlier Claude transcript sweep and date/cohort comparison are retired; old transcripts and the ignored local cohorts.json are left untouched.

## Commands

```sh
bench/measure verify --local            # compile, offline regression checks, git diff --check; no model calls
bench/measure verify --behavior         # inspect recorded matrix coverage; nonzero unless every case passed review
bench/measure verify --behavior --run   # start missing matrix sessions (paid), capped at 30 per retained batch
bench/measure run --scenario <case> --model <model>   # one case, same batch, same cap and gate
bench/measure analyze <events.jsonl> ...              # metrics for explicit codex exec --json files
```

Requirements: Python 3 standard library, Git, and for `--run` an authenticated Codex CLI with access to the requested models. `--run` starts real sessions and consumes usage allowance. The default batch is `bench/runs/effectiveness-v1` (ignored). Never reset or delete a batch to escape the cap or hide a failure; a failed or interrupted call still consumes its budget, while a model-access error (`unavailable`) does not and is retried on the next `--run`. Editing any hashed input marks earlier runs `stale` without refunding their sessions: a new harness version is validated in a new batch (`--batch <dir>`), which is a new budget the user authorizes.

Local success means the benchmark tooling works. It says nothing about the harness. Only `verify --behavior` exiting zero is behavioral acceptance, and that is a smoke gate over one matrix, not a reliability or token-savings claim.

## The matrix

Eleven cases in `bench/scenarios.py`, run on `gpt-5.6-luna` and `gpt-6-astra` at low reasoning, 30 sessions total. The cap rose from 26 with the two routing cases appended below, which pair a request with an open shape against a fully specified one; the first nine keep their prompts and fixtures unchanged, so their `input_hash` and their evidence stay comparable case by case, though `matrix()` now interleaves the new cases before the bootstrap pair. The unchanged handoff-v1 on Luna is always the first trial. Order and prompts are frozen in code; the `handoff-v1` prompts are byte-for-byte the original failed probe.

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
| route-bounded | 1 | fully specified ticket with a remote and the gh substitute: both stated behaviors land, committed, pushed, and a pull request attempted. No task list is required, since a one-step ticket does not owe one |

Each case seeds a standalone temporary repository outside this checkout so the project's root AGENTS.md cannot leak in. Harness cases get `agents/AGENTS.md` plus the skills they need copied into `.agents/skills/`. Bootstrap cases get only `harness-boostrap` and an ordinary Makefile project with a nested `src/AGENTS.md`. Forge cases get a local bare `origin` and a `gh` substitute (`bench/fixture_gh.py`) at `./.fixture/bin/gh` that supports `pr view/list/checks/edit`, logs every call to `.fixture/operations.jsonl`, and fails anything else. Fixture credentials are invalid and the sandbox has network disabled, so no real forge or tracker is reachable. The substitute is addressed by path, not PATH: Codex runs commands through a login shell that re-sources the profile, so a PATH prepend loses to the real `gh`. The `feedback` case runs with `danger-full-access` because workspace-write denies writes to `.git` and the case must commit and push; its remote is the local bare repository and its forge credentials are invalid. This is not hermetic: Codex may still load its own built-in or user-level instructions, which the manifest hashes as `ambient_instructions`.

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
