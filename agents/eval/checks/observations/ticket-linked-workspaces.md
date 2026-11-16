# Ticket-linked workspaces and PR references

Date: 2026-11-15. Starting revision: `a2822af0a8b3320b44923bdc527432f9527d9b9d`, with the local linkage changes applied. Selected sections were scope/new-thread-ticket-workspace and publication/ticket-linked-pr, with the shared-policy and authority boundaries in the common guide. No real host thread, checkout, tracker or product PR was created or changed for these evals.

## Frozen setup

Two disposable Git repositories used synthetic identities, disabled hooks/signing, committed seeds, existing task branches and local bare origins. Source hashes, full indexes, HEADs, local/remote refs and expectations were recorded before the workers started. The fixed instruction-manifest SHA-256 was `074678a86586970c3304d7d7685bf98e8ed3442815408ab10e0598fbda8cb8a7`. Fictional authoritative ticket snapshots supplied human identifiers, tracker kinds and distinct git-bug entity hashes. These were fixture data, not live tracker queries.

The launch worker received the shared policy and an ordinary request to start a new thread for its ticket, without mode activation. A local stand-in recorded only the actual launch arguments and returned a simulated result; it created no workspace or thread. The PR worker received explicit trusted mode activation and a completed nonvisual library scope, with a separate related ticket for future application integration. It could prepare a host handoff but could not publish. All evidence was stored outside tracked fixture source.

Expected decisions: new Git thread defaults to an explicitly bound worktree with the primary human ticket ID in its branch; an explicit reuse request selects root without renaming it; completed ticket scope uses Resolves while future work uses Refs; ticket records and existing source/ref state remain unchanged.

## Observed results

- New-thread turn: the worker read the shared policy, shared linkage guide, checker and fictional git-bug record. It prepared `feat/demo-7-ordered-values`, `baseRef: origin/main`, `startFromOrigin: true` and `workspaceStrategy.type: worktree`. It used the human ID rather than the entity hash. Shared launch preflight exited 0, then the local stand-in accepted the identical launch object. The worker's resource inventory reported no private-mode reads or activation.
- Same-session explicit-reuse turn: the user selected root and prohibited a new worktree or branch rename. The second plan recorded that instruction in reuse_reason and sent exactly `workspaceStrategy: {"type": "root"}`. Preflight and the stand-in both exited 0; the existing task branch was preserved.
- Ticket-linked host handoff: the worker executed the real fixture library demo and used the actual branch `feature/demo-9-library` in both linkage and delivery validation. An initial reference-format failure was corrected to plain `Resolves DEMO-9` and `Refs DEMO-10` lines. The final gate passed; the body kept application integration explicitly future/unverified and included the command demo and observed result. No publication, upload or ticket mutation occurred.

The lead inspected both actual launch records, preflight outputs, prepared PR content and command reports. Independent comparisons confirmed unchanged source bytes, indexes, HEADs, local refs and bare-remote refs in both repositories. The recorded stand-in arguments matched the validated plans. Worker resource inventories and command reports are not complete independently audited provider tool traces.

## Executable and structural checks

All 13 shared-checker tests and 17 private delivery-checker tests passed. They cover ticket token boundaries, missing workspace strategies, explicit reuse, exact-branch exceptions, valid scratch syntax, no-ticket cases, multiple ticket references, partial-work reasons, fenced references, malformed input, forbidden body paths and actual-branch integration through the delivery CLI. These checks validate declarations and actual supplied branch/body inputs, not the truth of a ticket status.

Private helper frontmatter, explicit-only entry metadata, policy/helper/script paths, eval section references, text hygiene and whitespace checks passed. Pinned vendor content, setup and CI were unchanged.

## Limits

The stand-in does not establish real T3 workspace binding, provider startup, automatic discovery, recommended Linear branch selection or multi-project registration. No actual git-bug close or Linear resolution automation was exercised or introduced. A Resolves line does not itself mutate the git-bug store. No-ticket, exact-user-branch, scratch and existing-worktree variants were exercised by code tests rather than additional model turns. The preflight is an agent-invoked check; it cannot intercept arbitrary host tool calls or prove that a declared reuse instruction or scope-completion claim is genuine.
