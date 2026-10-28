# Design

## Context

See proposal.md for the observed failure. The policy and shared skills are live-linked into multiple harnesses, so an old rule in a skill description can recreate a workflow even after its body changes. Existing eval fixtures often disabled review and delegation, hiding the exact decision this session exposed.

## Goals / Non-Goals

**Goals:** clear tasks finish with appropriate evidence; optional capabilities compose without extra gates; explicitly autonomous work persists through the agreed outcome. Instructions stay lean and modular, with one owner per shared concern.

**Non-Goals:** removing scope or secret boundaries, approving publication for this batch, merging, editing locked upstream skill bodies, or replacing Nix provisioning with host scripts.

## Decisions

### Capabilities replace mandatory routing

Keep a short capability index and essential boundaries in agents/AGENTS.md. Retain existing skill names for discoverability, but rewrite local descriptions and bodies so ordinary requests do not imply a full workflow. Remove lifecycle diagrams and historical explanations from agents/README.md. Rejected: adding a small-change exception to each mandatory workflow, which preserves the conflicting sources.

### Autonomy is an explicit delivery choice

A plan approval settles scope. Ordinary work completes the requested bounded change; yolo carries an explicit autonomous-delivery request through its stated outcome. Neither mode invents publication authority. A direct PR request uses open-pr without another contract or review gate. Rejected: inferring unattended delivery from task clarity, which made normal collaboration silently change mode.

### Proportional evidence, optional independence

principle-prove-it-works owns check selection, principle-test-agreed-decisions owns meaningful tests and principle-delegate-down-a-tier owns delegation. Respect required project checks. Independent review answers a concrete unresolved question, using one focused perspective unless distinct concerns justify two. Snapshots do not inflate reviewer count. Rejected: a risk score or a new mandatory classification document, which would add process to the decision being simplified.

### Keep workspace and continuity choices local

Reuse a task checkout and honor explicit placement. New isolated work uses worktrunk with a routine inferred name; unapproved hooks still need authorization. Keep one task list for substantial work and notes only where continuity helps. Do not start a new T3 conversation merely because a worktree was created. Rejected: mandatory branch and ledger approvals for reversible edits.

### Scoped publication, ordinary PRs

open-pr owns authorized commits, pushes and PR creation or refresh. Preserve human context and issue links. Use normal titles and drafts only when requested; remove automatic WIP title churn. Reuse unchanged check evidence and complete required remote checks when delivery includes a PR. Local feedback ends with a result rather than a publication question. Review replies remain scoped external messages.

### Keep setup declarative

Handy preferences live under macos/handy and each Home Manager account links the settings file into its own clone. Models, history and permissions remain account-local, and credential fields must stay empty. Account-local model setup is documented rather than introducing a synchronization service. Add mise once to the shared package declaration; reuse existing provisioning and shell checks.

## Risks / Trade-offs

- [Less fixed procedure permits inconsistent judgement] -> replay observed decisions through disposable sessions and inspect artifacts and transcripts.
- [Large snapshots obscure a small behavior change] -> scenarios combine a preference snapshot with a single link change and assert no automatic review.
- [A recipe or description retains a stale gate] -> search local policy, skill descriptions and bodies, docs and active change artifacts before running behavioral checks.
- [A shared settings file carries local state] -> keep model downloads and permissions local and document first-use setup; never promise that preferences provision models.

## Migration Plan

Revise this change's artifacts, replace controlling rules at their source, align scenarios with observable behavior, prepare disposable fixtures, then send the relevant prompts to gpt-6-luna subagents and review their transcripts and artifacts. Remove the Pi/OpenCode benchmark launcher; keep scenario preparation and assertions separate from the agent session. Validate setup through disposable checks without activating the host. Keep the diff local for review. Rollback is restoring the changed tracked files; no new service or runtime state is introduced.
