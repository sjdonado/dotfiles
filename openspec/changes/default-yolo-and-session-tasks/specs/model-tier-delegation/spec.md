## Purpose

Spending the capable model where it earns its cost, on understanding, planning, and orchestration, and delegating the mechanical stretches to a cheaper tier, without the instructions naming a model, an effort level, or a rule for when a subagent is warranted.

## ADDED Requirements

### Requirement: Delegation is offered before the expensive stretches

Before implementation begins, and again before verification begins, the agent SHALL offer to run that stretch in a subagent at a cheaper tier, in one line alongside the work rather than as a blocking question. The offer SHALL state what would be delegated. Declining SHALL keep the work in the current session.

#### Scenario: Interactive session before implementation

- **WHEN** the contract is settled and implementation is about to start in an interactive session
- **THEN** the agent offers to carry out the implementation in a subagent at a cheaper tier, names what it would hand over, and proceeds either way without waiting for permission to begin

#### Scenario: Interactive session before verification

- **WHEN** the implementation is complete and the checks or end-to-end verification are about to run
- **THEN** the agent offers the same for the verification stretch

### Requirement: Autonomous runs never stop for the offer

Under an autonomous workflow, the agent SHALL NOT interrupt the run to ask about delegation. It SHALL follow a delegation preference already recorded for the project, and where none is recorded, continue without delegating.

#### Scenario: Autonomous run with a recorded preference

- **WHEN** an autonomous run reaches implementation or verification and the project has a recorded delegation preference
- **THEN** that preference is followed with no question asked

#### Scenario: Autonomous run with nothing recorded

- **WHEN** the same run finds no recorded preference
- **THEN** the work continues in the current session, and the run does not stop to ask

#### Scenario: Answer given once

- **WHEN** the human answers a delegation offer
- **THEN** the answer is recorded as the project's preference, so the same question is not asked again in later sessions

### Requirement: Guidance stays model-agnostic

The instructions SHALL describe the orchestrator role and the tier split in general terms only. They SHALL NOT name a model, a model family, an effort or reasoning level, or a threshold at which a subagent becomes warranted. Choosing whether a task is worth delegating, and to what, SHALL remain the agent's judgement at the time.

#### Scenario: Reading the instruction

- **WHEN** the delegation guidance is read
- **THEN** it contains no model name, no effort or reasoning level, and no rule of the form "spawn a subagent when X", while still making clear that the orchestrating tier is the expensive one and mechanical work belongs below it

#### Scenario: A task that does not warrant delegation

- **WHEN** the work about to start is small enough that handing it over costs more than doing it
- **THEN** the agent does it directly, and the offer is not made for its own sake

### Requirement: Delegation accounts for what already runs below

Delegation decisions SHALL account for the subagents a workflow already spawns, so that the agents a run creates are not all at the expensive tier.

#### Scenario: A run that already spawns reviewers

- **WHEN** a workflow already dispatches its adversarial reviewers as subagents
- **THEN** those reviewers are treated as part of the run's cost when deciding what else to delegate and at what tier, rather than being counted as free
