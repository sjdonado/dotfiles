---
name: principle-test-agreed-decisions
description: Guidance for tests that establish changed behavior. Read when adding or changing a test.
---

Test the behavior the task requires, choosing the smallest reliable check that would catch a meaningful defect. Follow the project's existing testing conventions and required checks.

- Use unit, integration or journey tests according to where the behavior lives. A workflow stage does not determine the test type or whether tests are allowed.
- For a defect fix, prefer a regression check that fails without the fix. Add test files only when they add useful coverage; a reversible config edit can be established by its parser and provisioning assertions.
- For experiments, test settled behavior when useful without freezing unresolved product choices. Name uncertainties rather than writing assertions against a guessed requirement.
- Exercise real boundaries where practical. Avoid mocks that merely mirror the implementation or a new testing framework for a small change.
- Run existing relevant checks and explain any behavior that remains unverified.
