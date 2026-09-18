## Purpose

Gives the session's commander's intent one written home, so purpose, end state, and key tasks are gathered with the least human input and carried verbatim into implementation, verification, review, and handoff.

## ADDED Requirements

### Requirement: The branch note opens with Purpose, End state, and Key tasks

The branch note's Contract section SHALL begin with three fixed lines: **Purpose** (why this session exists, one sentence), **End state** (what done looks like, naming the acceptance evidence and making it machine-checkable where possible), and **Key tasks** (the path of the single task list). An agent SHALL write these lines at the first checkpoint of any workflow that edits files, and SHALL fill them from the request and repository evidence before asking the human for any of them.

#### Scenario: First checkpoint of a prototype

- **WHEN** `proto` reaches its first checkpoint
- **THEN** the note's Contract begins with Purpose, End state, and Key tasks, each filled from the request, the conversation, and repository evidence, with any part the agent could not derive marked as assumed

#### Scenario: Purpose derivable without asking

- **WHEN** the request states a goal and the repository shows the surfaces involved
- **THEN** the agent writes Purpose and End state itself and does not ask the human to restate them

### Requirement: Intent is refreshed before dependent work continues

When a human interaction changes the purpose or the end state, the agent SHALL update the three lines before making any further edit, and SHALL say in one line what changed.

#### Scenario: Feedback changes the goal

- **WHEN** feedback during a prototype loop redefines what done means
- **THEN** the End state line is rewritten before the next slice is built, and the response names the change

### Requirement: Downstream workflows read intent by path, not paraphrase

`yolo`'s understanding step, `verification`'s contract input, `handoff`, and Reviewer A in `adversarial-review` SHALL read Purpose, End state, and Key tasks from the note by path, or from the OpenSpec change's artifacts where one exists. An agent SHALL NOT substitute its own summary of the requirements for those sources when dispatching a subagent.

#### Scenario: Reviewer A dispatched under proto promotion

- **WHEN** `yolo` runs adversarial review on a diff promoted from `proto` with no OpenSpec change
- **THEN** Reviewer A receives the diff plus the note's Contract block verbatim, and nothing written by the implementer for the occasion

#### Scenario: Handoff written

- **WHEN** the `handoff` skill writes its document
- **THEN** the document points at the note for Purpose and End state and at the task list for Key tasks, and restates neither

### Requirement: The agent recommends a handoff when the session's intent has drifted or context has compacted

At a checkpoint, when the purpose or end state has changed twice in the session, or the conversation has been compacted, the agent SHALL recommend `handoff` in one line, with the reason, and SHALL continue the current step.

#### Scenario: Two goal changes

- **WHEN** a checkpoint saves and the End state line has been rewritten twice this session
- **THEN** the response includes a one-line recommendation to hand off and why, and the work does not stop
