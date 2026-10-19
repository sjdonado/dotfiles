# Spec Delta

## Purpose

Defines where a task's branch is checked out: always a worktrunk worktree of its own, named from the tracker when possible, so parallel tasks never share a working tree. A task is one piece of work agreed as a unit: it gets one branch, one worktree and one pull request, and follow-ups on that pull request stay the same task.

## ADDED Requirements

### Requirement: Every task runs in its own worktrunk worktree
When a workflow starts a new task that edits files, the agent SHALL create a new branch in a new worktree through worktrunk, based on the repository's default branch, and SHALL do all edits for that task in that worktree. The agent SHALL NOT branch in place in the user's checkout, and SHALL NOT create a worktree through any other tool. Work on an existing pull request continues in the worktree or checkout that already holds its branch.

#### Scenario: Starting new work
- **WHEN** the user asks for new work from a checkout on the default branch
- **THEN** the agent creates a worktrunk worktree on a new branch, reports its path, and edits files only there

#### Scenario: Continuing an existing pull request
- **WHEN** the user gives feedback on an open pull request whose branch is checked out
- **THEN** the agent works in that checkout and creates no new worktree or branch

#### Scenario: worktrunk unavailable
- **WHEN** `wt` is not on PATH
- **THEN** the agent stops before editing and says that worktrunk is missing

### Requirement: The branch name comes from the tracker or from the user
When the work is bound to a Linear issue, the branch SHALL be named with the issue's git branch name from Linear. Otherwise the agent SHALL propose a branch name and SHALL wait for the user to accept or replace it before creating the worktree.

#### Scenario: Linear issue
- **WHEN** the work starts from a Linear issue that has a git branch name
- **THEN** the worktree's branch has exactly that name and the agent does not ask for one

#### Scenario: No issue
- **WHEN** the work has no tracker issue
- **THEN** the agent proposes a name, waits, and creates the worktree with the accepted name

### Requirement: A new worktree inherits no branch notes
A new worktree SHALL NOT receive copies of another worktree's `.agent/` notes or task lists. The branch note and task list for the new branch SHALL be written in the new worktree.

#### Scenario: Ignored files are copied
- **WHEN** worktrunk copies ignored files into a new worktree
- **THEN** no file from the source worktree's `.agent/` directory exists in the new worktree

### Requirement: Worktree creation never blocks on a prompt
The agent SHALL create worktrees with options that produce machine-readable output and need no interactive input. When worktrunk requires approval for a repository's own hooks, the agent SHALL stop and ask the user instead of approving them on its own.

#### Scenario: Project hooks need approval
- **WHEN** creating the worktree would run project hooks that have not been approved
- **THEN** the agent reports which hooks and asks, and creates nothing until the user answers

### Requirement: The final report names the worktree
Every final report on work done in a worktree SHALL give the worktree's path, the command to open it, and the worktrunk command that removes it once its pull request merges.

#### Scenario: Report after a run
- **WHEN** a workflow returns after editing files in a worktree
- **THEN** its report includes the path, how to open it, and the `wt remove` command for it
