# Spec Delta

## Purpose

Defines the stages a task moves through, from finding the requirements to a finished pull request, and what each stage runs and deliberately skips, so expensive steps run once and only when the requirements have stopped moving.

## ADDED Requirements

### Requirement: Iteration finds the requirements cheaply
Work whose requirements are not settled SHALL run as `iteration`: in its own worktree on a new branch, in rounds of build, local checks, present, and fold in the owner's feedback, with a requirements ledger kept current. Iteration SHALL run only the local rungs of the oracle ladder, SHALL NOT run adversarial review, write new test files, push, or open a pull request.

#### Scenario: A round of feedback
- **WHEN** the owner gives feedback during iteration
- **THEN** the agent updates the slice and the ledger, runs the local checks, presents the result, and runs no adversarial review

#### Scenario: Asked to publish from iteration
- **WHEN** the owner asks to open a pull request while in iteration
- **THEN** the agent says that publishing needs the ledger accepted and moves to `yolo` or `open-pr` only with that acceptance

### Requirement: Iteration ends in exactly one exit state
Iteration SHALL end as one of: a PoC, a hand-off to `yolo`, or a killed premise. A PoC SHALL leave a runnable local demo in the worktree, with how to run it, what it proves, and what it fakes recorded in the ledger, and SHALL publish nothing. A killed premise SHALL record what died and the evidence.

#### Scenario: PoC
- **WHEN** the owner chooses a PoC
- **THEN** the worktree holds a demo the owner can run with the recorded command, and no commit is pushed

#### Scenario: Kill
- **WHEN** the iteration disproves the premise
- **THEN** the ledger records what died and why, and the worktree is left for the owner to remove

### Requirement: Yolo builds on the iteration
`yolo` SHALL start from an accepted iteration ledger or another settled contract, in the worktree that holds the work. It SHALL add what iteration skipped: tests for the decisions the ledger marks, adversarial review over the whole accumulated diff, publication through `open-pr`, and driving every check green. A PoC SHALL be able to move to `yolo` the same way, with its ledger as the contract once the owner accepts it.

#### Scenario: Hand-off from iteration
- **WHEN** the owner accepts the iteration's ledger and asks to finish the work
- **THEN** `yolo` continues in the same worktree and branch, and the iteration's diff is preserved

#### Scenario: Review runs once
- **WHEN** a task went through five iteration rounds and then `yolo`
- **THEN** adversarial review ran once, during `yolo`, over the final diff

### Requirement: Moving to the next stage needs the owner's acceptance
A ledger or PoC the agent produced SHALL NOT move work to the next stage on its own. Moving from iteration or PoC to `yolo` SHALL require the owner's acceptance of the ledger's scope.

#### Scenario: Agent-finalized ledger
- **WHEN** the agent finalizes a ledger and the owner has not answered
- **THEN** no commit is pushed and no pull request is opened
