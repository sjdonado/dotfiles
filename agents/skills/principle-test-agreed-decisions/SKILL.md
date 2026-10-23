---
name: principle-test-agreed-decisions
description: Not a workflow; read when a step names it. When to write tests and which kind. Read before writing or changing a test.
---

Not a workflow: workflows and building blocks read this when a step names it.

A test pins a decision the user agreed to. Write it only after that decision stops moving.

- **Before the scope is agreed, write no test files.** This covers `iteration`, `poc`, brainstorming and MVP slices. Prove a slice by running it and by the existing ladder. Where an existing assertion fails because the slice changed that behavior on purpose, update that assertion and add none. Record in the requirements ledger each confirmed decision that a test must pin. The exception is a user who asks for a test.
- **Once the scope is agreed, `yolo` writes the tests** from the decisions the ledger says a test must pin, or, where no ledger lists them, from the contract's acceptance criteria. `feedback` and `address-review` add or change a test only when their change adds or alters an agreed decision or fixes a defect: a defect fix gets a regression test that fails without the fix.
- **A unit test only for isolated business logic**: a formula or rule that must hold whatever the architecture around it becomes.
- **An end-to-end test for everything else.** Walk the user journey through the real stack and assert the decisions made along it. One journey that covers several decisions is better than one test per function.
- **Do not mock internal modules, and do not build an integration only to make a test runnable.** Stub only what the test environment cannot reach (a third-party service, payments, the clock) at the outermost boundary. Where the repository has no end-to-end harness, use its existing runner at the highest level it reaches and name the gap in the PR. A named gap is still incomplete coverage, never a pass.
- Name the decision a test pins, in its name or a one-line comment, so a failure says which agreement broke.
