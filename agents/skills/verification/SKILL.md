---
name: verification
description: Drive a change's checks to green in a named subagent and report back. Runs the oracle ladder, fixes what the change broke, and returns a verdict. Use when a workflow needs its checks run, so verification is attributable and can sit on a cheaper tier than the session orchestrating it.
---

# Verification

Running checks and chasing their failures is mechanical work against a settled contract. It is the other half of what a run spends outside implementation, and until it has a name it is indistinguishable from every other subagent, so nobody can say what verification costs. This skill gives it one, the way `adversarial-review` names the review half.

It is the natural place for a cheaper tier: the contract is fixed, the oracle is machine-checkable, and success is not a judgement call.

## Invocation

Dispatch as a subagent with the work to verify, not with the conversation. Give it, and nothing else:

- the branch or diff under test, and where the contract lives (an OpenSpec change directory, a task list, a ticket, or a one-line statement of what the change is meant to do)
- the resolved oracle ladder if the caller already resolved it, so it is not re-derived
- any check the caller already knows is failing for an unrelated reason

Do not pass the implementation rationale. A verifier that knows why you believe the code is right will read a failure as noise.

## What it does

1. Resolve the ladder per `AGENTS.md` if it was not handed over: the project's own instructions, else its declared task runner, else the toolchain. Record what was inferred.
2. Ascend one rung at a time, cheapest first, each green before the next. Re-derive the failure list on every pass; never work from a stale one.
3. Fix what this change broke. Auto-fix lint and format, rebase when the branch is behind its base, re-run provisioning on an install, cache or port failure, and re-run a flake once before counting it as an attempt, per the do-not-escalate list in `AGENTS.md`.
4. Stop on a rabbit-hole trip: the same check failing three times under three different fixes, two attempts that produced no new information, a diff growing past roughly three times what the change implied, or a fix that would touch a surface outside the stated intent.

## What it never does

Redesign. A failing check is fixed at its cause inside the change's scope; a failure that can only be resolved by changing what the change is for is an escalation, not a repair. It also never commits to the default branch, never pushes, never opens or merges a pull request, and never touches an escalation surface (schema and data migrations, CI configuration, dependency lockfiles, shared or public contracts, infrastructure as code, auth and secrets) unless the contract it was handed names that surface.

Unrelated pre-existing failures are reported, not fixed. Absorbing them makes the diff unreviewable and hides whether this change is sound.

## What it reports

The caller needs a verdict it can act on without re-running anything:

- each rung, with its command and its final state: green, still failing, or skipped because the project has no such rung
- what was fixed to get there, in one line each
- anything left red, with the failure output and what each attempt disproved
- anything inferred rather than resolved from the project's instructions, so a wrong inference is visible
- a rabbit-hole trip, if one happened, with the smallest next hypothesis

A rung that cannot run is reported as unverified. Never as passing, and never quietly skipped.
