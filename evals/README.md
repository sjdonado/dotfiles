# Harness benchmarks

Each `scenarios/<name>.yaml` is a benchmark fixture: it defines a disposable repository, the conversation prompts, and deterministic outcomes to inspect after each turn. Run the prompts with native Luna subagents from the parent session. The fixture does not start agents, score their reasoning, or infer skill reads from tool traces.

## Commands

From the repository root:

```sh
bun evals/run.ts list
bun evals/run.ts prepare yolo-bounded /tmp/yolo-bounded
bun evals/run.ts check yolo-bounded /tmp/yolo-bounded 1
```

`prepare` writes the fixture into an empty requested directory, creates a local bare `origin`, installs the current shared agent instructions and skills under `.agents/skills`, applies scenario setup, records the turn 1 baseline, and prints its prompt. Choose a fresh directory for each independent run. The fake `gh` command is at `.fixture/bin/gh`; give the subagent this environment when invoking it:

```sh
PATH="$PWD/.fixture/bin:$PATH" GH_HOST=example.invalid
```

Run the printed prompt with a Luna subagent. For each subsequent turn, call `begin <scenario> <directory> <turn>` exactly once to apply its setup, record the pre-turn commit and print its prompt, then run `check <scenario> <directory> <turn>` after the subagent finishes. `prepare` begins turn 1 automatically. The checker evaluates only declared repository state: branch, commits relative to that turn's baseline, pushes, files, PR fixture fields and shell assertions. It cannot check which skills were read, commands used, or quality of the agent's explanation. Inspect the conversation yourself for those properties. Keep the prompt text and outcome assertions separate from the subagent's assessment; the agent should not see expected results while working.

The checkout is disposable and `gh` refuses unsupported operations. No real forge is configured. The scenario fixtures may contain their own detailed checks in `expect.check`; these execute from the prepared repository with `$SEED` set to the initial commit. `begin` is required for every turn after turn 1, including turns without a `setup` block.

## Scenarios

| Scenario | Focus |
| --- | --- |
| `dotfiles-setup` | Handy preferences and mise on the current branch, then a scoped commit beside staged editor settings |
| `happy-path` | Isolated local implementation and feedback on the same task branch |
| `iteration-gate` | Keep open scope local and ask the unresolved question |
| `plan-approval` | Approval to implement does not imply publication |
| `yolo-bounded` | Bounded request through a PR |
| `open-pr` | Resolve a failing check before opening a PR |
| `feedback` | Batch local feedback and leave unrelated staged work untouched |
| `address-review` | Triage review threads and publish only after approval |
| `land` | Close out only after merge |
| `ask` | Answer a bounded question read-only |
| `risk-review-selection` | Recognize when independent review is warranted |

`gh.ts` is the local forge substitute used by these fixtures. It serves a seeded PR and records supported operations in `.fixture/operations.jsonl`.

For `dotfiles-setup`, read the resulting README before accepting the run: it must explain per-account clones, saving and quitting Handy before committing and pushing, closing Handy before pulling and reopening in another account, and the account-local models and permissions. The file assertion locates the Handy section; the parent assesses whether those instructions are usable.
