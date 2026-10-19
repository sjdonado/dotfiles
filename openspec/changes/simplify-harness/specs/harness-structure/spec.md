# Spec Delta

## Purpose

Defines how the agent harness is organized, so that each rule lives in one place and workflows reuse the same principles and steps instead of restating them.

## ADDED Requirements

### Requirement: The shared policy holds routing and hard boundaries only
The globally linked policy SHALL contain only skill routing and the boundaries that must hold in every session, such as publication authority, secrets, never merging, and the chat writing rules. Any other rule SHALL live in exactly one principle, building-block or workflow skill.

#### Scenario: A rule appears once
- **WHEN** the harness is searched for a given rule, such as the oracle ladder's rung order or the commit message format
- **THEN** its normative text is found in one skill, and every other mention refers to that skill by name instead of restating it

#### Scenario: Boundaries hold without a skill loaded
- **WHEN** a session loads no skill at all
- **THEN** publication still requires an agreement, secrets are still never read, and nothing is merged

#### Scenario: Every-turn boundaries stay in the policy
- **WHEN** the shared policy is read
- **THEN** it holds the three-kinds preamble, routing with the planning routes, the principles index, publication authority, where work happens, the surfaces that escalate on first touch, secrets, who may start a review, the chat writing register with the dash, hard-wrap and link rules, and MCP server placement and tool naming, and nothing else

### Requirement: Principles are loaded by name, never entered as workflows
Each principle SHALL be a short skill named `principle-<name>` that owns one concern, stated as triggers, required actions and stop conditions. A principle SHALL NOT be entered as a workflow by plain-language routing; a workflow or building block that relies on it SHALL name it, and the agent SHALL load it when that step runs.

#### Scenario: Principle stays out of routing
- **WHEN** a user's request matches the words in a principle's description but not any workflow
- **THEN** the agent does not enter the principle as a workflow

#### Scenario: Workflow loads its principles
- **WHEN** a workflow reaches a step that names a principle
- **THEN** the agent loads that principle before acting on the step

### Requirement: Building blocks are reusable steps
A building block SHALL be a skill that performs one step any workflow may need (creating a worktree, verifying with the oracle ladder, adversarial review, opening a pull request) and that can also be entered directly when the user asks for that step. A building block SHALL keep its own entry conditions and gates whichever way it is entered.

#### Scenario: Entered from a workflow or directly
- **WHEN** the same building block is entered once from a workflow and once from a direct user request
- **THEN** it runs the same steps and enforces the same gates both times

### Requirement: Workflows are thin compositions
A workflow skill SHALL contain its entry rule, the ordered steps that name the principles and building blocks they use, and its exit states. It SHALL NOT restate the procedure of a building block or the text of a principle.

#### Scenario: Changing a shared step
- **WHEN** a building block's procedure changes
- **THEN** no workflow skill needs editing for the change to take effect in every workflow that uses it

### Requirement: git-bug is driven by a skill, not a server
The harness SHALL drive git-bug through a `git-bug` skill that uses git-bug's non-interactive CLI, and SHALL configure no git-bug MCP server. The skill SHALL treat `git bug push` as a publication that needs the user's approval, SHALL never launch git-bug's interactive interfaces, and, when another process holds git-bug's repository lock, SHALL report that process's id and wait instead of retrying or removing the lock.

#### Scenario: No server
- **WHEN** the harness configuration of any agent is inspected
- **THEN** no git-bug MCP server is configured

#### Scenario: Push needs approval
- **WHEN** the agent has created a bug and the user has not approved publishing it
- **THEN** `git bug push` is not run

#### Scenario: Repository locked
- **WHEN** `git bug termui` is open in another terminal and the agent needs to read bugs
- **THEN** the agent reports the lock holder's process id and waits for the user
