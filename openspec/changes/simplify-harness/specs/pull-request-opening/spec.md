# Spec Delta

## Purpose

Publishes a requested change with scoped authority and relevant evidence while preserving the existing pull request's human context.

## ADDED Requirements

### Requirement: Publication follows scoped authorization
A direct request to open or update a PR SHALL authorize the necessary commits, push and PR refresh for that scope. Local implementation, plan approval, passing checks and PR existence SHALL NOT grant publication authority. The agent SHALL NOT require a separate workflow or ledger acceptance for an already authorized diff.

#### Scenario: Direct PR request
- **WHEN** the user asks to open a PR for a clear current diff
- **THEN** the agent uses open-pr without requiring yolo or independent review

#### Scenario: Local feedback only
- **WHEN** the user requests local feedback changes without authorizing publication
- **THEN** the agent finishes them locally and reports the result without appending a publication question

### Requirement: Publication uses appropriate check evidence
Before committing, pushing or creating a PR, the relevant required local checks SHALL pass. When PR delivery is requested, the agent SHALL complete required remote checks and assess mergeability. Current evidence SHALL be reusable while its inputs remain unchanged.

#### Scenario: Known failing check
- **WHEN** a requested publication has a relevant local check failure
- **THEN** the agent fixes an authorized defect before publishing, or reports the failure and publishes nothing

#### Scenario: No edits permitted
- **WHEN** a user requests publication as-is and prohibits edits but a required check fails
- **THEN** the agent reports the failure without editing or publishing the failing change

### Requirement: PR presentation serves the reader
The PR SHALL use a normal title or a draft when requested, without automatic temporary title markers. Its body SHALL explain the problem, behavior, actual verification and meaningful limitations, preserving human context and issue links when refreshed.

#### Scenario: Simple change
- **WHEN** a small change is published
- **THEN** the PR explains the change and checks without a mandatory diagram or temporary WIP title

#### Scenario: Existing PR
- **WHEN** authorized feedback is pushed to an existing PR
- **THEN** its description is updated in place and existing human context and issue links are preserved

### Requirement: Delivery never merges
PR delivery SHALL stop at the requested outcome or a concrete blocker and SHALL NOT merge the pull request.

#### Scenario: Checks green
- **WHEN** all requested checks and mergeability are green
- **THEN** the agent reports completion without merging
