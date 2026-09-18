## Purpose

Makes delegation to subagents the default for mechanical stretches, at a tier below the orchestrator, so it happens without an offer that the autonomous path never makes.

## ADDED Requirements

### Requirement: Verification runs one tier down by default

Under `yolo`, the `verification` stretch SHALL run in a subagent at a tier below the orchestrator unless the project's own instructions record a different preference. The orchestrator SHALL hand it the contract path, the resolved ladder, and any check already known to fail for an unrelated reason, and nothing else. No offer to delegate SHALL be made; the recorded preference or this default applies.

#### Scenario: Yolo reaches the ladder

- **WHEN** an approved `yolo` run finishes implementation and the project records no delegation preference
- **THEN** `verification` is dispatched to a subagent at a lower tier with the contract path and ladder, and the run does not stop to ask

#### Scenario: Project records a preference

- **WHEN** the project's `AGENTS.md` names the tier or says to verify in session
- **THEN** the agent follows that record without asking

### Requirement: Reviewers stay at the orchestrator's tier

`adversarial-review` reviewers SHALL run at the orchestrator's tier unless the project records otherwise, because a reviewer too weak to find the bug is not a saving.

#### Scenario: Reviewers dispatched

- **WHEN** `adversarial-review` dispatches its reviewers
- **THEN** they run at the orchestrator's tier and the run records that choice in the PR body only if it deviated

### Requirement: Competing approaches fork to lower-tier subagents

In `proto`, when the End state is written and two or more approaches are plausible, the agent SHALL build them as a fork iteration: one subagent per approach at a lower tier, each in its own worktree with the End state and the local ladder, results compared against the End state and presented to the human as the iteration. A fork SHALL NOT run while the End state line is missing.

#### Scenario: Two plausible approaches

- **WHEN** a prototype loop has a written End state and the agent sees two approaches whose tradeoff the human would want to see
- **THEN** it builds both in parallel subagents in separate worktrees and presents the comparison, and nothing is committed

#### Scenario: End state missing

- **WHEN** the End state line is not yet written
- **THEN** the agent does not fork and instead writes the End state or builds the single next slice

### Requirement: Waiting is never delegated

An agent SHALL NOT dispatch a subagent whose job is to watch a running process or poll for completion. A long-running command SHALL run in the session that can see it through.

#### Scenario: Paid batch in flight

- **WHEN** a benchmark batch is running
- **THEN** the orchestrator waits on it in session and dispatches no watcher
