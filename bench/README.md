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

## Interpreting the numbers

Output tokens are the spend that tracks model effort. `cache_read_input_tokens` grows with session length and context size and is the main cost of long sessions, which the first measured datapoint made concrete: one 8-day interactive session read 345M cached tokens while all tool results combined were only ~288KB. Instructions that trim tool output help less than instructions that end loops sooner or delegate recon to sidechains (`sidechain_messages` counts those).

LLM runs are not deterministic; the tasks, criteria, and fresh-session isolation are the deterministic part. Treat small deltas as noise and rerun once before believing a big one.
