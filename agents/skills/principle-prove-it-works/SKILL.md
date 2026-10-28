---
name: principle-prove-it-works
description: Guidance for evidence proportional to the changed behavior. Read before validating work or claiming completion.
---

Choose checks that establish the changed behavior and relevant failure modes. Respect project-required checks; resolve commands from AGENTS.md, the declared task runner or repository evidence, in that order.

Start with focused inexpensive checks, then broader checks when the change or project requires them. A parser can establish valid configuration; a provisioning check can establish where it is linked. A large snapshot does not require an application test suite or independent review solely because of its size.

Run each check with an observable exit status. A long-running command belongs to the session that started it. Reuse recorded evidence while its inputs remain unchanged; rerun affected checks after a substantive change. Fix failures introduced by the task and distinguish unrelated failures. A missing tool or check is unverified, never passing.

Publication is a separately authorized action, not a verification rung. When delivery includes a PR, required remote checks and mergeability are part of that outcome. Never push merely to claim local work complete.

For harness behavior, follow the project's disposable-session benchmark instructions: declare expectations before running, retain unedited evidence and inspect transcripts as well as artifacts. A dry run validates wiring, not model behavior; one successful scenario does not prove efficiency. Compare usage only where it was actually recorded.
