# Spec Delta

## Purpose

Keeps task work in the appropriate checkout and provides isolation when needed without interrupting ordinary edits for reversible workspace choices.

## ADDED Requirements

### Requirement: Reuse the task checkout
The agent SHALL reuse the task or PR checkout and honor the user's placement choice. New independent work needing isolation, including new work from the default branch, SHALL use the worktree capability. Unrelated dirty work SHALL remain preserved.

#### Scenario: Follow-up on the current branch
- **WHEN** the user asks to keep a settings change on the current work-in-progress branch
- **THEN** the agent edits there without creating a new branch or conversation

#### Scenario: Independent task
- **WHEN** the agent starts independent work from the default branch
- **THEN** it creates an isolated task checkout without committing to the default branch

### Requirement: Routine branch names do not require confirmation
The agent SHALL use an explicit user or tracker branch name when available, otherwise choose a short appropriate name without requiring confirmation.

#### Scenario: No supplied branch name
- **WHEN** independent work needs a branch and the user has not named one
- **THEN** the agent chooses a routine name and proceeds

### Requirement: Project hooks retain their authorization boundary
Creating a worktree SHALL NOT silently approve untrusted hooks. The agent SHALL inspect required project hooks and ask only when running them falls outside existing authorization.

#### Scenario: Unapproved hooks
- **WHEN** worktree creation would run project hooks without authorization
- **THEN** the agent identifies the hooks and does not approve them itself

### Requirement: New worktrees do not inherit another task's state
A new task checkout SHALL NOT retain copied notes or checklists belonging to another task. The agent SHALL report the path of a newly created checkout and how to open it.

#### Scenario: Copied ignored notes
- **WHEN** worktree creation copies ignored files from another checkout
- **THEN** the new task does not use the other task's notes as its own
