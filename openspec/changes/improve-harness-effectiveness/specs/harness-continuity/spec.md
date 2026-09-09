## Purpose

Preserve the user's contract and verified progress across existing skills and sessions without duplicate task tracking or implicit authorization.

## ADDED Requirements

### Requirement: Portable project instructions

The harness-boostrap skill SHALL audit or create/update repository agent instructions based on the requested intent and repository evidence. Generated instructions SHALL identify useful project structure, setup, verification commands, scoped constraints, and unresolved gaps without requiring this harness's skills, note format, models, or personal workflows. It SHALL preserve valid existing conventions and report unsupported claims rather than fabricate commands.

#### Scenario: Audit existing instructions

- **WHEN** the user requests an audit of root and nested instruction files
- **THEN** the skill reports evidence-backed gaps and contradictions without changing any files or running consequential setup commands

#### Scenario: Set up an ordinary project

- **WHEN** the user requests setup in a repository without agent instructions
- **THEN** the skill writes concise instructions grounded in the repository's actual tools, records unknowns, and introduces no dependency on the author's personal harness

#### Scenario: Repeat setup

- **WHEN** the skill is applied again without changes to evidence or requirements
- **THEN** it preserves the instruction content without duplicate sections or cosmetic churn

#### Scenario: Scoped or linked instructions

- **WHEN** instruction files have nested scope or link to a managed location outside the repository
- **THEN** the skill preserves scope and does not overwrite the external target as an incidental setup action

### Requirement: Durable checkpoint

Writing workflows spanning rounds or sessions SHALL preserve the current contract, unresolved work, and essential rationale in the shared branch note at their existing checkpoint. They SHALL keep authoritative tasks in their existing artifact and report any failure to persist the handoff.

#### Scenario: Prototype awaits feedback

- **WHEN** a prototype round finishes its local checks
- **THEN** its ignored, untracked branch note records the implemented behavior, deferred requirements, essential rationale, check result, and awaiting-feedback next action before the workflow returns

### Requirement: Recover without inventing requirements

On continuation, workflows SHALL recover requirements from the note or authoritative artifacts before changing dependent behavior. If a product requirement cannot be recovered, they SHALL ask one focused question, preserve completed work, and make no change dependent on that answer. A missing note alone SHALL NOT require a question.

#### Scenario: Missing note but available contract

- **WHEN** the note is missing and a referenced approved contract supplies the deferred requirement
- **THEN** an authorized writing workflow reconstructs the necessary state and continues without asking again

#### Scenario: Missing contract

- **WHEN** a continuation references a deferred requirement absent from available artifacts and context
- **THEN** the workflow requests that requirement and does not implement or claim completion of a guessed substitute

### Requirement: Consistent authority and state

The shared rules SHALL own approval and terminal-state semantics. Skills SHALL reference those rules rather than contradict them. A plan, research finding, or note SHALL NOT create approval. Read-only workflows SHALL NOT modify repository or note state.

#### Scenario: Planning input without implementation approval

- **WHEN** the user asks to analyze or plan from a handoff
- **THEN** the workflow produces only the requested analysis or planning artifacts and does not implement or push

### Requirement: Current PR description

After an authorized push, the responsible workflow SHALL update the existing PR title and body to reflect the verified diff, preserve human-written context and links, and record unresolved work. A deferred round SHALL retain check debt without pushing. Reviewer replies SHALL retain their existing explicit approval boundary.

#### Scenario: More feedback is expected

- **WHEN** a validated feedback round is pushed and another round is expected
- **THEN** the PR description reflects the pushed state without waiting for the later round and the note records that feedback remains pending

### Requirement: Post-merge closure without OpenSpec

Landing SHALL verify that the associated PR merged before marking its existing note complete, whether or not an OpenSpec change exists. It SHALL run spec verification and archival only when the change exists and SHALL preserve the note for explicit cleanup.

#### Scenario: Ordinary merged PR

- **WHEN** the associated PR is merged and has no OpenSpec change
- **THEN** landing completes its existing note without creating or archiving specs

#### Scenario: Unmerged PR

- **WHEN** the associated PR remains open
- **THEN** landing reports awaiting merge and does not mark its note complete
