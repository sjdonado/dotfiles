# Spec Delta

## Purpose

Defines how a pull request is opened or refreshed, in one place that any workflow or a direct request can use, so every pull request gets the same gates, prose and lifecycle.

## ADDED Requirements

### Requirement: One skill opens and refreshes pull requests
Committing, pushing, opening a pull request, refreshing an existing pull request's title and body, and the `WIP:` title lifecycle SHALL be performed by a single `open-pr` skill. `yolo` SHALL use it for its publication step, and a direct request such as "open a PR" SHALL enter it.

#### Scenario: Direct request
- **WHEN** the user asks to open a pull request for the current branch
- **THEN** the agent enters `open-pr` without running `yolo`

#### Scenario: From yolo
- **WHEN** `yolo` reaches its publication step
- **THEN** it publishes through `open-pr`

### Requirement: Opening a pull request needs an agreement and green local checks
`open-pr` SHALL publish only when the agreement required for publication holds for the diff being published. A direct request that names the pull request counts as that agreement for the branch's current diff, unless the branch note holds an iteration ledger with an open acceptance question, which `open-pr` SHALL ask about once before publishing. Before pushing, `open-pr` SHALL run the local rungs of the oracle ladder and SHALL NOT publish while any of them fails.

#### Scenario: Red local check
- **WHEN** the user asks to open a pull request and a local check fails
- **THEN** no commit is pushed and no pull request is opened, and the failure is reported

#### Scenario: Default branch
- **WHEN** the current branch is the repository's default branch
- **THEN** `open-pr` publishes nothing and says a task branch is needed

### Requirement: Pull request prose explains the change
A pull request body SHALL explain the problem, the resulting behavior and the verification, following the repository's template or recent merged pull requests when no template exists. When a change spans several components, a flow across processes, or a state machine, the body SHALL include a mermaid diagram of it. A change a reader understands from its prose alone SHALL NOT get a diagram.

#### Scenario: Complex change
- **WHEN** the diff changes how three or more components interact
- **THEN** the pull request body contains a mermaid diagram of that interaction

#### Scenario: Simple change
- **WHEN** the diff is a single-file fix
- **THEN** the pull request body contains no diagram

### Requirement: The WIP marker tracks the checks
A new pull request SHALL be opened as a normal pull request whose title starts with `WIP:`, unless the user asked for a draft. The marker SHALL be removed only after every resolved check and the mergeability check are green.

#### Scenario: Checks still running
- **WHEN** a pull request has just been opened and its required checks are running
- **THEN** its title starts with `WIP:`
