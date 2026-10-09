# Harness scenario tracking

Minimal declarative regression slice: same four scenarios run against each harness version and each model. Paid runs only on explicit authorization.

## Layout

- `scenarios.json`: scenario source of truth using the existing Promptfoo shape (providers, tests, assertions). Two providers (`sol-medium`, `luna-medium`), four tests, TypeScript artifact checks and a default latency assertion. The runner supports `openai:codex-sdk` entries through Pi's `openai-codex` provider; unknown providers and empty selections fail.
- `run.ts`: Bun runner with no packages. Copies fixture artifacts, materializes current repository instructions, seed commits them, creates a local bare remote and live forge substitute, spawns isolated `pi-agent --mode json`, and runs artifact checks. `pi-agent` remains the upstream CLI; `pi` now opens the custom Durable harness.
- `inputs.ts`: copies current `agents/AGENTS.md` and skill trees, appends fixture guidance, and records SHA-256 hashes of these inputs plus the runner, scenario JSON, forge substitute, checks and selected fixture. Obsolete fixture skill copies have been removed; historical run evidence remains intact.
- `checks/*.ts`: artifact assertions shared via `(output, {providerResponse: {metadata: {workingDir, seedHead, workspaceDiff}}})`. Git commit and remote heads, the forge operation log, and posted issue bodies determine publication and closure. Final prose names the unresolved caching decision, checkout location and feedback checkpoint.
- Bounded work requires a successful `yolo` read, committed and clean `label.py`, validation execution, a matching pushed head before PR creation, and a checkout report naming the fixture path or branch in the same sentence. Mixed scope requires a successful `proto` read, local validation, unchanged branches and no observed publication command. Recoverable work requires grounded rationale, an ignored updated note, validation, no publication, and a stop or acceptance question backed by the saved feedback state.

## Models

Pinned to `gpt-6.1-sol` and `gpt-6-luna` at `medium` thinking. Earlier 2026-10-07 attempts recorded a Sol access error (`not supported when using Codex with a ChatGPT account`); access must be judged from each fresh attempt. Missing usage is unknown (`null`), including provider errors, rather than zero. Additional providers and a full matrix port remain deferred.

## Commands

Free, run anytime:

```
bun run.ts --list
bun run.ts --dry-run
bun run.ts --dry-run --filter-pattern recoverable
python3 -m json.tool scenarios.json >/dev/null
bun build checks/*.ts --outdir /tmp/tscheck-build && rm -rf /tmp/tscheck-build
```

Paid, only when explicitly authorized (recoverable smoke is 2 sessions, full side by side is 8):

```
bun run.ts --run --filter-pattern recoverable
bun run.ts --run
```

Each `--run` invocation creates a unique ignored `results-*` directory. Every attempt retains its final fixture repository and bare remote, exact prompt, input hashes, Pi version and full command, isolated settings description, transcript, stderr, result, and aggregate results. Execution uses a temporary repository outside this checkout to avoid inheriting its project instructions; the final repository snapshot is copied into the attempt directory. A started result records the execution path before setup so interruptions remain visible, including the temporary repository when a process is interrupted before the snapshot. Setup failures retain their diagnostics. Earlier root-level transcripts remain historical evidence.

The runner exits nonzero on any assertion failure, setup error or provider error. A final Pi `error` or `aborted` message fails even when the process exits zero. A transient error followed by a complete successful turn stays visible in `providerErrors`. Incomplete or malformed transcripts fail. `skill-used` requires a successful completed native `read` call for the named `SKILL.md`; mentions in the prompt or output do not count. Unsupported assertions fail. Default assertions are merged with each scenario's assertions. Dry runs report seed-state negatives and unknown latency without calling Pi.

Validation evidence comes from successful completed native Bash calls that run the fixture's `check.py` or Python assertions exercising `label`. Assertions may be inline, in a heredoc, or in the exact executed Python file whose resolved path stays inside the fixture; files reached through symlinks outside the fixture and secret-named paths are rejected. A marker file or quoted command mention is insufficient. The shared command check distinguishes direct Git operations and shell wrappers from quoted searches, and catches publication followed by resets or branch deletion. Arbitrary script indirection remains a transcript-review concern. External reply checks require repository citations, resolved dependency facts, allowed dash prose, an actionable mismatch between the four-item title and the single documented dependency, ordered forge operations and unchanged tracked code. Transcript review judges the meaning of these statements and whether a mock check was described accurately; the external `check.py` prints test claims and does not run those tests.

## Native code mode

Both Pi eval paths explicitly load `builtin:codemode` and `builtin:mcp` despite `--no-extensions`. The isolated agent directory receives only managed `defaultTools: ["+codemode"]`, `codemode.mode: "on"` and an empty `mcp.json`. Native read, Bash, edit and write tools remain direct. Do not replace this selection with Pi 1.0.2's CLI `--tools` allowlist: it prevents later-registering MCP tools from becoming callable inside code mode. No live browser, simulator, git-bug or personal-account server is connected by the eval runner. Results record effective settings, the complete command and the managed settings hash. The four paid JSON scenarios and their model settings are unchanged; earlier evidence remains historical, not acceptance of this new configuration.

## Phase continuation

The opt-in `phase-continuation` case uses the existing `bench/measure` fresh-process rounds instead of another multi-turn runner. Its three prompts and assertions are declared in `bench/scenarios.py`: planning saves the Northstar casing reason without code edits or Ponytail activation; implementation reads Ponytail, normalizes whitespace and saves an ignored note; fresh planning recovers the reason and compares module memory, caller storage and no cache without edits or Ponytail activation. Every round checks Git and forge actions for publication. Transcript review must separately judge the substance of the three tradeoffs, planning skill routing and phase-local intensity; keyword and tool checks cannot establish these meanings.

After explicit paid authorization, from the repository root:

```sh
bench/measure run --scenario phase-continuation --model gpt-6-luna --batch bench/runs/<new-approved-batch>
bench/measure run --scenario phase-continuation --model gpt-6.1-sol --batch bench/runs/<new-approved-batch>
```

The `run` subcommand starts paid sessions directly. This costs six sessions, stays outside the default acceptance matrix, and shares the existing retained batch cap. Review every transcript and write the hash-bound `review.json` described in `bench/README.md`. Free offline positive and negative checks run through `bench/measure verify --local`. This declaration is not behavioral acceptance.

## Reading results

Pass rate per model first, then token usage medians among passing runs with known usage only. Report unknown usage separately. Never pool models or scenarios, and compare costs only when recorded by the provider. A provider error (auth, model access) is reported distinctly from an assertion failure so access gaps never read as harness regressions. This slice tracks missing PR creation after push (`route-bounded`), missing local check execution (`external`), ungrounded reply facts, publication from mixed scope, and recovery of the earlier prototype rationale. Transcript review remains required before behavioral acceptance.

## Coverage retirement decision

Keep the overlapping Python cases. This four-scenario slice does not establish parity with the larger matrix, and the retained legacy regression contains both task failures and matcher disagreements. The user approved publishing the eval tooling with those failures documented, not treating the behavioral gate as green. Historical batches remain ignored local evidence. Retire a Python row only after repeated runs with the same prompts and model settings establish equivalent artifact and transcript coverage. No token savings or general harness acceptance is claimed by this migration.
