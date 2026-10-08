# Tasks

## 1. Own runner scaffold

- [x] 1.1 Create `evals/harness/run.ts` (Bun, stdlib only, under 200 lines) reading `promptfooconfig.yaml` via `Bun.YAML.parse` with `--list` and `--help` and verify both run with no model calls
- [x] 1.2 Implement per test fixture copy to a temp dir plus `git init` seed commit, then `pi --mode json` spawn with the exact `bench/measure` isolation flags, and verify `--dry-run` copies, commits the seed, skips `pi`, and exits zero

## 2. Transcript assertions

- [x] 2.1 Parse `pi` JSONL transcripts (final text, usage, `tool_execution_end`, `SKILL.md` reads), implement `javascript` plus `skill-used` assertions with warn and skip for other types, and verify `--dry-run` runs every check against seed state and reports negatives
- [x] 2.2 Reuse `checks/*.js` unchanged via CJS import with `{workingDir, workspaceDiff}` context and verify the offline pos/neg cases from the Promptfoo slice still hold through the runner

## 3. Docs and parity

- [x] 3.1 Update `evals/harness/README.md` with `bun` commands, explicit `--run` gating for paid sessions, results handling, and the Sol on ChatGPT login finding, and verify every free command runs as written
- [x] 3.2 Record `promptfooconfig.yaml` as retained scenario source of truth for a later provider swap and verify `bench/` stays untouched

## 4. Paid runs, deferred

- [x] 4.1 Run recoverable smoke via the own runner on luna only (1 session) once `--run` is explicitly authorized and verify the result matches the Promptfoo smoke pass
- [x] 4.2 Run the full side by side once Sol auth is resolved and record the retirement decision for overlapping custom matrix rows; retain Python coverage because parity is not established

## 5. Python to Bun port

- [x] 5.1 Port `bench/fixture_gh.py` to `evals/harness/gh.ts` with identical log format, fix the `process.exit` skips `finally` divergence with throw plus `exitCode`, and verify `bun test gh.test.ts` reports 3 pass
- [x] 5.2 Wire `gh.ts` into `run.ts` as `.fixture/bin/gh` materialized per temp copy, name transcripts by test slug, store output text in results rows, ignore transcript artifacts, and verify `--dry-run` plus `bun test` stay green
- [x] 5.3 Re-run route-bounded plus external via `--run` once authorized; the live substitute executes both forge workflows, with model and assertion failures retained rather than counted as acceptance

## 6. Local configuration follow-up (2026-10-07)

- [x] 6.1 Remove the nine Moshi Claude hook commands while preserving Herdr and non-hook settings
- [x] 6.2 Validate JSON and compare remaining settings/hooks with HEAD; no provisioning or paid model run
- [x] 6.3 Save the local checkpoint and report publication status

## 7. Ponytail coherence and code-mode assessment (2026-10-08)

- [x] 7.1 Reconcile Ponytail triggers, phase-local persistence, output scope and every invoking workflow without changing publication boundaries
- [x] 7.2 Refresh evaluation inputs from current instruction sources and assert actual forge/Git actions rather than terminal claims; retain all run evidence
- [x] 7.3 Declare and add a planning/code/planning continuation scenario with independent artifact and tool-action checks
- [ ] 7.4 Free checks and six skill frontmatter validations pass; authorized paid behavioral runs expose failures and oracle gaps, with evidence and transcript reviews retained; acceptance remains incomplete
- [x] 7.5 Complete the initial code-mode assessment and record Pi as eval-only; the initial deferral is superseded for OpenCode/Pi by section 9, while Claude/Codex and Pi Durable remain deferred
- [x] 7.6 Save the verified local checkpoint, unknowns and specific remaining authority

## 8. Approved eval-simplification PR

- [ ] 8.1 Make JSON the scenario source and harden only the runner gaps needed for honest measurements and assertions; no new dependencies. Three evaluator defects remain unresolved; section 9 supersedes the original exclusion of Pi configuration changes
- [x] 8.2 Reconcile artifacts with the earlier eval-only scope; the expanded OpenCode/Pi scope now requires confirmed artifact revisions under 9.5, with Claude/Codex and Pi Durable deferred
- [x] 8.3 Run local verification, fresh retained TypeScript evals, phase continuation and declared legacy regression; review all transcripts and document legacy failures under the user's explicit publication exception, without claiming behavioral acceptance. Final JSON: 6/8 artifact and 7/8 semantic passes; final phase: six artifact checks and both semantic reviews pass; evaluator defects remain blocking under 8.1/8.5
- [x] 8.4 Record the overlapping-case parity/retirement decision without losing older evidence or unrelated coverage; keep every overlapping Python row
- [ ] 8.5 Complete adversarial review, commit only this batch, push and open the PR; drive resolved remote checks and mergeability green, never merge. Publication held after second-round evaluator defects; awaiting user direction on a bounded repair

## 9. Native code-mode prototype on the same branch

- [x] 9.1 Trace installed OpenCode/Pi native code-mode activation, managed links and eval isolation; equivalent setup uses each client's native adapter with matching developer MCP definitions and direct native file/shell tools, without replacing either runtime
- [x] 9.2 Enable OpenCode's native adapter in mise and the default Fish shell; native debug execution passes without credentials, model calls or unrelated tool changes
- [x] 9.3 Configure eval-only Pi's native code mode and matching developer MCP definitions; both paid runner paths retain isolated effective settings and empty live MCP inputs
- [x] 9.4 Exercise actual nested calls offline through both native adapters; 28 tests and 204 assertions plus local tooling/syntax pass. Retain failures, report full provisioning unverified and fresh paid behavioral acceptance still pending
- [ ] 9.5 Prototype checkpoint saved and artifact revisions proposed; await the expanded acceptance/publication agreement before promotion. Handoff requested, not acceptance of the pending revision, evaluator-repair or paid-run scope

## 10. Pi daily-driver prototype

- [x] 10.1 Verify Durable CLI compatibility with extensions; experimental TUI explicitly lacks extensions, so regular Pi CLI is selected for the clarified daily-driver goal. Background-tasks is suitable for noninteractive shell jobs; subagents supplied separately
- [x] 10.2 Configure pinned Pi packages, process-only background tasks, subscription models and existing MCPs/skills; Pi RPC startup discovers commands and shared skills without paid calls, auth check reports ready, all four MCP servers connect
- [x] 10.3 Exercise process launch, output, cancellation and tool discovery offline; disposable RPC smoke captures marker output and records cancellation, docs state Durable limitations and no fresh paid coding/subagent acceptance

## 11. Custom Pi Durable harness, agreed direction

- [x] 11.1 Record command naming: custom general-purpose interactive Durable harness is `pi`; upstream standalone CLI is `pi-agent`. Current commands remain unchanged until the custom host exists
- [ ] 11.2 Write the Durable host contract for arbitrary projects, Codex subscription auth, shared instructions/skills, MCP code mode and subagents; preserve section 10 as an intermediate CLI prototype
- [ ] 11.3 Plan explicit process ownership and bounded cleanup: task-owned jobs stop when their owner finishes; session-owned servers stop on harness exit; terminate descendants and verify cleanup without touching unrelated processes
- [ ] 11.4 Plan durable launch/status/log records and restart reconciliation: distinguish stopped, interrupted and verified-live jobs, retain what was running, allow explicit agent restart without blindly replaying commands or trusting stale/reused PIDs
- [ ] 11.5 Verify the eventual command split and update child-process/eval launchers so standalone invocations use `pi-agent` rather than recursively launching the custom harness
- [ ] 11.6 Exercise future lifecycle scenarios offline: normal exit, task completion, cancellation, hard crash/reopen, stale PID and explicit restart; no orphaned owned processes and no duplicate restart side effects

## 12. Native Pi-agent UI in the Durable host

- [x] 12.1 Reuse native editor, message/tool cards, collapse/expand behavior and theme controller; offline tests verify no phantom system/tool rows and bounded tool rendering
- [x] 12.2 Add native model/thinking/theme pickers, slash/skill completion and settings controls; actual terminal test selects Sol and opens settings without inference
- [x] 12.3 Restore native-style usage/context/model footer while preserving process status, use the upstream viewport/dock and its one-row composer gap; offline/native terminal checks cover layout and message separation

## 13. Provider/search/resume/side conversations

- [x] 13.1 Inspect pi-web-search 1.7.0 and Codex commit 2fdf047c9631c9ed01a31b62efb7891718a931a8; docs record native search limits and reference-only fork semantics
- [x] 13.2 Reuse Go credentials only in model-runtime memory; CLI lists 30 configured Go catalog entries plus Sol/Luna/Astra, and tests preserve the credential store without inference
- [x] 13.3 Adapt the pinned search package, normalize nullable headers/source-only type boundary, preserve errors and unknown usage; Codex/Go mock-request and unsupported-route tests pass without live search
- [x] 13.4 Add exact --session resume and native-style project picker; tests verify explicit selection over a newer empty session, canonical directory identity and the exact exit hint
- [x] 13.5 Add reference-only /btw forks and /back; tests prove main work continues, side tools are read/search only, answers stay out of the parent and closing marks the side closed

## 14. pi-durable home and one-on-one command parity

- [x] 14.1 Move the harness to `pi-durable/` as the future separate repository; `bin/pi` launches from the new home, `pi/` keeps only `pi-agent` configuration
- [x] 14.2 Remove the duplicative `/models` command and CLI flag; model browsing stays in the native `/model` picker
- [x] 14.3 Add `/login` using the upstream provider selector plus OAuth/API-key dialog and `ModelRuntime.login`; typecheck plus 19 passing tests cover the command list
- [x] 14.4 OpenCode Go removal was implemented then reverted per provider-parity direction; providers stay untouched and come back through upstream parity, 19 tests pass
- [x] 14.5 Extract the harness to `~/Development/pi-durable` as its own repo (https://github.com/sjdonado/pi-durable), pushed to main; document the repeatable upstream upgrade in `UPSTREAM.md`; `bin/pi` delegates to the checkout

## 15. PSS scheme install via mise

- [x] 15.1 Replace `[tasks.pi-sync]` with `[tasks.pss-sync]` running the scheme's own `install.sh` from GitHub; wire `macos.sh` and `linux.sh` after the tool installs
- [x] 15.2 Remove the stale `bin/pi` delegate (its checkout is gone) so `pi` resolves to upstream; `pi-agent` unchanged
