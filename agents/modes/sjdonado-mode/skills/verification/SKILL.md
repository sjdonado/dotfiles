---
name: verification
description: Run checks appropriate to a change, fix failures it introduced and report evidence. Short checks can run in the current session.
---

Establish whether the requested behavior works using principle-prove-it-works and the project's required checks. Delegate only when the work benefits from a separate worker (principle-delegate-down-a-tier).

A delegated verifier receives the diff or branch, authoritative requirements or their path, resolved check commands and known unrelated failures. Give no implementation rationale. A small change does not need a new contract document to run a check.

Run focused checks, then broader checks when required. Fix failures introduced by the task without redesigning it or absorbing unrelated changes. Do not activate a host, install tools or mutate external services solely to validate documentation. A command's completion is not evidence until its exit status and relevant assertions were inspected.

Report commands, final results, fixes and anything still unverified. Name inferred checks so their scope can be assessed. Do not commit, push, open a PR or start an independent review as part of verification.
