# Spec Delta

## Purpose

Lets a session choose experiments, collaboration and autonomous delivery independently, preserving the user's scope and authority without mandatory graduation.

## ADDED Requirements

### Requirement: Experiments are optional recipes
Iteration and PoC SHALL support working slices and runnable demos without being prerequisites for ordinary implementation or publication. Tests SHALL follow useful behavior coverage rather than a lifecycle stage.

#### Scenario: Owner feedback
- **WHEN** the owner asks to try an approach and then changes a requirement
- **THEN** the agent refines the working slice and checks it without imposing a graduation or ledger-acceptance gate

### Requirement: Autonomous delivery is explicitly selected
The harness SHALL select autonomous delivery only when explicitly requested. Approval of a plan or specification, clarity of requirements and an existing PR SHALL NOT independently select yolo or authorize publication.

#### Scenario: Plan approval
- **WHEN** the owner approves a plan for a local implementation
- **THEN** the agent performs the requested implementation without silently starting autonomous PR delivery or publishing

#### Scenario: Explicit autonomous request
- **WHEN** the user asks the agent to work independently until the PR and required checks are green
- **THEN** the agent resolves routine decisions and failures through that outcome without routine permission checkpoints

### Requirement: Autonomous work stops for real blockers
An autonomous run SHALL persist within its authorized scope and stop for missing authority, an essential unresolved decision, a contradicted premise or repeated attempts yielding no useful evidence. It SHALL report incomplete checks rather than claim the agreed outcome.

#### Scenario: Routine failure
- **WHEN** an in-scope local check fails because of the new implementation
- **THEN** the agent fixes it and reruns the affected check without requesting permission to continue

#### Scenario: Missing capability
- **WHEN** a required check cannot run because its necessary service is unavailable
- **THEN** the agent records the check as unverified and reports the concrete blocker
