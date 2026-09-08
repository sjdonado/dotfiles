# bench

Test one concrete harness behavior in a disposable repository, retain the evidence, and measure the sessions that attempted it. Correctness comes first: fewer tokens in a failed task are not an improvement. This replaces automatic Claude transcript sweeps and date/cohort comparisons with explicit, reproducible scenarios and Codex exec JSONL analysis. Old transcripts and the ignored local cohorts.json are left untouched; the old --all, --report, and --split interface is retired.

## Run the handoff probe

Requires Python 3, Git, and an authenticated Codex CLI with access to the requested model. This starts two real model sessions and consumes your normal usage allowance.

```sh
bench/measure run
# Explicit model, no fallback:
bench/measure run --model gpt-5.6-luna
```

The runner prints a new directory under ignored bench/runs/. Each attempt seeds its own repository on proto/handoff, copies the current AGENTS.md plus proto and ponytail skills, and starts two separate ephemeral Codex sessions with GPT-5.6 Luna and low reasoning. The second session gets neither the first prompt nor its conversation. User configuration is disabled; authentication and built-in/user-level instructions may still be supplied by Codex. This is a controlled fixture, not a hermetic runtime. Raw events come from codex exec --json, documented at https://learn.chatgpt.com/docs/non-interactive-mode.

The prompts explicitly skip commits, pushes, PRs, delegation, and external services. The CLI uses workspace-write, and each round has a five-minute timeout. The runner makes only the fixture's seed commit and never pushes. No existing worktree is reset or removed. Run artifacts stay available for inspection and explicit cleanup.

## Scenario: handoff-v1

Round 1 asks proto to normalize whitespace in label.py while preserving case. It provides a business reason for casing and defers a specific blank-input fallback to the next round. Round 2 asks for the deferred behavior and a rationale document without repeating either fact. This tests whether proto uses ponytail and leaves enough durable context to continue in a fresh session.

Assertions are declared in the runner before either model executes:

- Both rounds: expected label behavior, same branch, an existing refreshed note at the prescribed path, ignored and untracked.
- Round 2: the exact deferred fallback and the earlier branding rationale survive. The rationale check is a keyword smoke check; read the document to confirm meaning.

Inspect transcripts for actual skill reads, note consumption, redundant exploration, false completion claims, and a useful next action. Note existence and modification alone do not establish good state. This scenario does not test yolo, PR rendering, feedback/address-review, land, branch switching, or every harness rule. Add a small scenario only when an observed gap warrants it.

## Read the evidence

Each run retains result.json, per-round prompts, JSONL events, stderr, note snapshots, and the final fixture. The manifest records UTC start time, requested model, reasoning effort, CLI version, source commit, and content hashes of AGENTS.md and both skills. Hashes distinguish uncommitted harness edits. Model is labeled requested because exec events do not necessarily identify the serving model.

result.json separates artifact checks from session metrics and reports each round's pass/fail. The runner exits nonzero if any round fails, times out, or cannot complete. Preserve failed attempts; do not retry until green and then report only the survivor.

```sh
bench/measure analyze bench/runs/<run>/round-1.jsonl bench/runs/<run>/round-2.jsonl
```

The same analyze command accepts future sessions captured with codex exec --json. Supply explicit event files, not internal Codex rollout files or Claude transcripts. It emits one JSON row per file: terminal status, reported token usage, completed tool items, failed items, and command-output bytes. It counts completion once per item, not both its start and finish. Missing usage remains null, unfinished sessions remain incomplete, and malformed JSON fails visibly. analyze reports observations; a completed turn does not imply the task passed. It does not invent costs, interruption counts, permission-denial classifications, or model identity that the stream does not provide.

## Compare harness versions

First inspect correctness and continuation. Then repeat the same scenario with the same model, reasoning, CLI, and environment against each harness version. Keep all attempts, compare pass rates, and compare median input/output tokens, cached input separately, tool calls, and wall time among successful runs. Record sample counts and variability. Do not pool different scenarios or models, and do not claim savings from one pair. Alternate version order when possible to reduce timing/cache bias. Failure rate and manual intervention remain part of the result even when successful runs are cheap.

For ordinary sessions, retain the task and expected outcome alongside the event file, inspect the final artifacts, and use analyze for cost/friction observations. Such sessions can expose missing scenarios, but unrelated tasks are not an A/B comparison. Raw artifacts can contain private context and stay ignored; publish only deliberately selected, inspected findings.

Local checks: python3 -m py_compile bench/measure; python3 bench/test_measure.py; git diff --check. A red behavior probe is a finding about the harness, not a reason to weaken the assertions.
