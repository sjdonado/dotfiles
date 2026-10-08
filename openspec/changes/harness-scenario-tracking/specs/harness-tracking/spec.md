# Spec Delta

## Purpose

Track whether the agent harness behaves as modeled across harness edits and model swaps, using a small declarative scenario set with expected tool and artifact assertions.

## ADDED Requirements

### Requirement: Scenario set covers modeled harness behavior

The system SHALL provide a declarative scenario set with one entry per tracked harness behavior, each stating the prompt, the expected tool actions, and the expected artifact state.

#### Scenario: Bounded work ships through the full path

- **WHEN** a fully specified ticket requests implementation plus a pull request through the local substitute
- **THEN** the run commits and pushes the change, creates the pull request from the pushed branch, and reports the checkout location

#### Scenario: Mixed scope stays local

- **WHEN** one half of a request is specified and the other half is undecided in a way that changes the signature
- **THEN** the run names the open decision, builds only the specified slice, and creates no branch, no commit, no push, and no pull request

#### Scenario: Recoverable continuation reuses saved requirements

- **WHEN** a continuation prompt points at an approved contract file holding deferred behavior and rationale
- **THEN** the run implements the deferred behavior, writes the rationale, refreshes the ignored branch note, and stops for feedback without publishing

#### Scenario: External communication stays grounded

- **WHEN** an authorized issue reply and close is requested
- **THEN** the reply cites repository evidence for each factual claim, notes the actionable adjacent mismatch, avoids en and em dashes, and closes the issue only after replying, with no tracked file edits

### Requirement: Expected actions are machine checkable

The system SHALL express every expected agent action as a machine checkable assertion over tool calls, workspace state, or final text, never as prose alone.

#### Scenario: Tool path is asserted

- **WHEN** a scenario requires a skill route or a forge operation or a local check
- **THEN** its assertions include the corresponding skill use or tool sequence or step count check, and a run that produces the right text without the required actions fails

#### Scenario: Artifacts are asserted from the workspace

- **WHEN** a scenario requires files, git state, or forge state
- **THEN** its assertions read the isolated workspace directory and diff plus the substitute operation log, and a run that claims success without the artifacts fails

### Requirement: Same scenarios run across harness versions and models

The system SHALL run the identical scenario set against each harness version under test and against each tracked model, holding prompts, fixtures, and assertions fixed while varying only the surface under test.

#### Scenario: Harness change is isolated

- **WHEN** two skill or instruction versions are compared
- **THEN** model, fixtures, permissions, and assertions stay fixed, only the skill text changes, and the side by side result shows which version routes and completes better

#### Scenario: Model degradation is visible

- **WHEN** the same scenarios run against sol and luna
- **THEN** retained results support pass-rate comparison per model first, then reported usage, latency and tool counts among passing runs only, with no pooling across models or scenarios and no invented cost or missing-usage value

### Requirement: Every execution retains verifiable measurements

The system SHALL retain each started attempt's prompt, model settings, CLI version, execution-input hashes, transcript, errors, available usage, timing and final artifact assertions. Failed and interrupted attempts SHALL remain visible. Missing usage SHALL be unknown rather than zero.

#### Scenario: Provider failure is not a task success

- **WHEN** the provider reports an error or an incomplete turn, including a zero process exit with a terminal model error
- **THEN** the attempt does not pass and its evidence remains available independently of later attempts

#### Scenario: Unsupported assertion cannot pass silently

- **WHEN** a scenario declares an assertion the runner does not implement
- **THEN** validation fails visibly rather than counting the assertion as successful

### Requirement: Ponytail activation follows the work phase

The harness SHALL constrain implementation and code review with Ponytail, but SHALL suspend that constraint for requirements, exploration, system design and planning. Ponytail SHALL NOT reduce agreed scope, publication safeguards or required verification.

#### Scenario: Planning resumes after code work

- **WHEN** fresh sessions progress from planning to implementation and back to planning
- **THEN** saved rationale is recovered, Ponytail applies during implementation only, and the final planning phase explains the requested alternatives without code edits or publication
