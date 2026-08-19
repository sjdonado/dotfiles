# bench

Reference points for tuning the agent harness. Capture a labeled run before a change to `agents/`, capture another after, and compare numbers instead of impressions.

## Method

`bench/run <label>` executes every task in `tasks/` in its own fresh headless session (`claude -p`), so tasks share nothing and the interactive history stays clean. Each task file opens with an `expect` HTML comment naming its success criteria; the runner strips that comment so the criteria never steer the model. Results land in `runs/<label>/` as the raw result JSON plus a metrics JSON per task.

`bench/measure <session-id|jsonl>` extracts the metrics from any transcript, including interactive sessions: wall time, prompts, tool calls by name, token usage split by kind, tool-result bytes by tool, and the largest single tool results.

Quality stays a human judgment against each task's `expect` line. The tool only makes the cost side objective; a run that got cheaper by answering worse is a regression, not a win.

## What the tasks cover

| Task | Exercises |
| --- | --- |
| 01-lookup | one-line lookup stays unrouted and cheap |
| 02-route-research | routing to /research, ledger shape, read-only discipline |
| 03-triage | /triage: kill-query ordering, evidence ledger, plan brief, no edits |
| 04-ask | /ask: one focused sourced answer |
| 05-conversational | a cheap question stays cheap |

The battery is deliberately read-only: an implementation task would mutate the repo and make runs incomparable. When a /yolo benchmark is worth its cost, it needs a fixture repo of its own.

## Model

The battery always runs on the cheap tier: `haiku` under Claude Code (the runner's default, `BENCH_MODEL` overrides it), `luna` when driving it through opencode on the OpenAI side. Two reasons. The battery exists to be run often, before and after every harness change, and five sessions on a frontier model would make that a decision instead of a habit. And absolute numbers are model-dependent anyway: a delta only means something between two runs on the same model, so the daily-driver model buys nothing here. Never compare runs across models; `runs/<label>/meta.json` records which model produced a run so a cross-model diff is visible when it happens.

The tradeoff is real and accepted: a cheap model fails quality criteria a frontier model would pass, so a quality miss on the battery is a signal to check, not proof the harness change is bad. Cost deltas transfer across tiers much better than quality does.

## Subagents

`measure` reports `sidechain_messages`: messages produced by subagents rather than the main loop. Harness changes that delegate recon (the `/triage` delegation default, `/research` parallel tracks) show up as this number rising while main-loop context, and with it `cache_read_input_tokens`, falls. That is the shape of a successful delegation change. Subagent traffic lands in the same transcript, so its cost is already included in the totals; nothing extra to add up.

## Interpreting the numbers

Output tokens are the spend that tracks model effort. `cache_read_input_tokens` grows with session length and context size and is the main cost of long sessions, which the first measured datapoint made concrete: one 8-day interactive session read 345M cached tokens while all tool results combined were only ~288KB. Instructions that trim tool output help less than instructions that end loops sooner or delegate recon to sidechains (`sidechain_messages` counts those).

LLM runs are not deterministic; the tasks, criteria, and fresh-session isolation are the deterministic part. The first baseline/after pair put numbers on the noise: an untouched control task swung 4x in output tokens between runs, so on haiku a single-run delta under that band means nothing. Rerun before believing any movement, and read the control tasks first; if they moved as much as the treated one, the comparison is void.

Two fixture rules learned the same day. The repo is the fixture, so a task must not search anything the battery itself writes; saved runs under `bench/runs/` contain the tasks' own search terms, which is why 02 scopes its search to named directories. And a task meant to exercise delegation must not name the exact files, since the delegation rule's own exception (read directly when the item names the file) then correctly suppresses what the task was written to measure.
