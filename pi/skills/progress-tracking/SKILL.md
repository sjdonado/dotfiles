---
name: progress-tracking
description: Maintain PI_PROGRESS.md for long-running mutating workflows with a current run, commit-linked history, notes, and strict step transitions. Use only when a prompt explicitly requests progress tracking.
---

# Progress Tracking

The caller supplies a workflow name, checklist, optional initially completed items, and terminal status. Maintain `PI_PROGRESS.md` in the Git repository root.

## Setup

1. Resolve the root with `git rev-parse --show-toplevel` and the local exclude file with `git rev-parse --git-path info/exclude`.
2. Add `/PI_PROGRESS.md` to that exclude file if absent. Never modify `.gitignore`.
3. Use this structure:

```markdown
# PI Progress

## Current run

Workflow: <workflow>
Status: in progress

- [ ] First concrete step

## History
```

## Run lifecycle

Before starting a new run:

- Move the previous `## Current run` to the top of `## History`.
- Preserve its checklist and item-local notes.
- Label it `### <workflow> — <commit hashes>` and retain its final status.
- If the old file is an unsectioned checklist, archive the whole checklist.
- If no commit was recorded, label it `interrupted, no commit`. Never associate it with the new run's commit.
- Keep history newest first.

Create a fresh `## Current run` from the caller's checklist. Replace placeholders with concrete task items before implementation. Mark any caller-declared initially completed items with notes showing what was established; leave all others unchecked.

## Updates

- Add concise indented notes under the relevant item for evidence, decisions, files changed, failures, assumptions, skipped checks, verdicts, or URLs.
- Update each checkbox and its notes immediately after completion and before starting the next item.
- Never begin the next item while the completed item remains unchecked.
- Record each commit hash under its item before pushing.
- Update `Status` whenever the workflow waits, pushes, opens a PR, finishes, defers review, or fails.
- Leave the completed file in place.

The progress file reports work; it never replaces verification, user-visible summaries, PR descriptions, or review replies.
