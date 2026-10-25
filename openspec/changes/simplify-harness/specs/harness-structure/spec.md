# Spec Delta

## Purpose

Provides independent agent capabilities and proportional evidence without forcing ordinary requests through an end-to-end workflow.

## ADDED Requirements

### Requirement: Clear requests can be handled directly
The harness SHALL let the agent inspect, implement and verify a clear bounded request without a mandatory workflow, plan, ledger or graduation step. Skill discovery SHALL describe available capabilities rather than force routing.

#### Scenario: Ordinary settings change
- **WHEN** a user requests a small settings link on the current task branch
- **THEN** the agent makes the local change and runs relevant required checks without a planning or publication prompt

### Requirement: Shared concerns have one owner
The shared policy SHALL hold always-on boundaries and a short capability index. Shared concerns SHALL live in their principle or building-block skill; optional recipes SHALL reference them rather than duplicate their rules.

#### Scenario: A rule changes
- **WHEN** the check-selection principle changes
- **THEN** recipes use the updated guidance without restating a separate check ladder

### Requirement: Evidence follows behavior and risk
The agent SHALL choose tests, checks and delegation for the changed behavior and failure modes while respecting required project checks. Workflow membership, file count and line count SHALL NOT independently require review or delegation.

#### Scenario: Large preference snapshot
- **WHEN** a local settings change contains a large preference snapshot and one link declaration
- **THEN** its size does not trigger independent reviewers and the agent checks parsing and the relevant provisioning behavior

### Requirement: Independent review answers a concrete question
The agent SHALL use independent review when requested or when a concrete unresolved concern warrants it. One concern SHALL use one focused perspective; two reviewers SHALL require distinct concerns. Requirements review SHALL use identifiable authoritative requirements.

#### Scenario: Existing pull request
- **WHEN** a small follow-up is made on a branch with an open PR
- **THEN** PR existence does not trigger independent review

#### Scenario: Concrete compatibility concern
- **WHEN** a data-format change has unresolved compatibility consequences
- **THEN** the agent investigates them and uses focused independent inspection if it can resolve the concern, reporting unavailable review honestly

### Requirement: Durable state serves continuity
The harness SHALL require persistent task state only when continuity benefits from it. Substantial work SHALL reuse one authoritative checklist; small self-contained edits SHALL NOT require a branch note or ledger.

#### Scenario: One local edit
- **WHEN** the task can be completed and explained in one self-contained change
- **THEN** the agent can finish without creating .agent notes or a task list

### Requirement: git-bug remains a CLI capability
The harness SHALL use git-bug's non-interactive CLI without a git-bug MCP server. Publishing issues SHALL require scoped authorization. A repository lock SHALL be reported rather than removed or bypassed.

#### Scenario: Locked issue repository
- **WHEN** another process holds git-bug's repository lock
- **THEN** the agent reports the lock and does not remove it or retry indefinitely
