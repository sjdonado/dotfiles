## Purpose

Task state for work that is not running under an OpenSpec change, so what a session is doing and has finished survives into the next session and is readable by a subagent, and so the route into autonomous implementation is the default rather than something the human has to insist on.

## ADDED Requirements

### Requirement: Implementation defaults to the autonomous workflow

A request to implement, build, fix, or carry out an agreed plan SHALL enter the autonomous implementation workflow without asking, whether it arrives as a plain request, an approved plan, a handoff document, or a contract produced by another workflow. The prototyping workflow SHALL be entered only when the human asks for one, in their own words, such as prototype, spike, rough, or a request to try something first. The agent's own judgement that requirements feel uncertain SHALL NOT select prototyping.

#### Scenario: Plain implementation request

- **WHEN** the human asks for something to be implemented and names no workflow
- **THEN** the autonomous implementation workflow runs, announced in one line, with no request for permission to begin

#### Scenario: Handoff with no written contract

- **WHEN** a session starts from a handoff document that asks for work to be carried out, and no OpenSpec change or written plan exists
- **THEN** the autonomous implementation workflow runs against the handoff as its input, rather than stopping to ask which workflow applies

#### Scenario: Prototype asked for explicitly

- **WHEN** the human asks to prototype, spike, or try something rough first
- **THEN** the prototyping workflow runs instead, and nothing in it opens a pull request

#### Scenario: Uncertain requirements without a prototype request

- **WHEN** the agent judges the requirements underspecified but the human asked for implementation
- **THEN** the autonomous implementation workflow still runs, deciding the open points and recording each decision with the fact that would reverse it, rather than switching to prototyping

### Requirement: Work worth documenting is offered a written contract

When a request is large enough to be worth a durable written contract, the agent SHALL say so in one line and offer the written-spec route before starting, rather than silently choosing the cheaper in-conversation route. A refusal or silence SHALL proceed with the cheaper route.

#### Scenario: Multi-surface feature request

- **WHEN** the human describes work touching several surfaces or whose reasoning is worth keeping after the pull request merges
- **THEN** the agent names the written-spec route in one line and proceeds on the human's answer, without blocking on it for work that can start either way

### Requirement: Session task state outside a written change

Work that is not running under an OpenSpec change SHALL keep a task checklist for the session, in the same shape as an OpenSpec change's task list: numbered, grouped, and ticked as each item lands. It SHALL live beside the branch note, be created when the work has more than one step, and be updated at the same points the branch note is written.

#### Scenario: Multi-step work without a written change

- **WHEN** a session begins work of more than one step and no OpenSpec change directory covers it
- **THEN** a task checklist is created beside the branch note, and items are ticked as they are completed rather than at the end

#### Scenario: A subagent needs to know what is done

- **WHEN** a subagent is dispatched work that depends on what the session has already finished
- **THEN** the checklist is available to it by path, so the state does not have to be restated in the prompt

#### Scenario: Continuing in a new session

- **WHEN** a later session picks up the same branch
- **THEN** it reads the checklist for what is done and what remains, and continues from there rather than re-deriving the plan

#### Scenario: Handoff written mid-flight

- **WHEN** a handoff document is produced for another agent
- **THEN** it references the checklist by path rather than restating the task list

### Requirement: The task ledger has one owner and one lifetime

The session checklist SHALL NOT compete with either the branch note or an OpenSpec change's own task list. Where an OpenSpec change exists, its task list is authoritative and no session checklist is kept. Where a session adopts an OpenSpec change mid-flight, the checklist's content SHALL be folded into the change and the checklist removed. The checklist SHALL be removed when the work lands.

#### Scenario: OpenSpec change adopted mid-session

- **WHEN** work that began with a session checklist moves to an OpenSpec change
- **THEN** the checklist's remaining and completed items are carried into the change's task list, the checklist is deleted, and the human is told it was folded in rather than discarded

#### Scenario: Work merges

- **WHEN** the pull request for the work merges and the landing workflow runs
- **THEN** the session checklist is removed as part of closing out, the same way an OpenSpec change is archived

#### Scenario: An OpenSpec change is already in play

- **WHEN** work is running under an OpenSpec change directory
- **THEN** no session checklist is created, and the change's own task list is ticked instead
