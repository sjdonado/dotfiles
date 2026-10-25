---
name: agent-review
description: Run focused independent review for a requested review or a concrete unresolved correctness, security or compatibility concern. Do not trigger from PR existence, publication or diff size.
---

Use independent inspection when it can answer a specific question left unresolved by ordinary investigation and checks. Name that question before delegating. Do not invoke this skill merely because a workflow names review, a PR exists or a snapshot has many lines.

Choose the narrowest useful review. One reviewer is enough for one concern. Use two only when distinct concerns need independent perspectives; give each a separate question. Never choose reviewer count from file or line thresholds. When no independent reviewer tool is available, say so; self-inspection is not an independent review.

Reviewers are read-only and start without the implementer's conversation or rationale:

- For requirements coverage, pass the relevant diff and identifiable user requirements or the authoritative specification, verbatim. If those requirements are unclear, resolve them with the user rather than reviewing against an invented contract.
- For bug finding, pass the relevant diff, the concrete concern and raw evidence needed to inspect it. Apply ponytail when a simpler implementation could preserve all required behavior; do not substitute stylistic preferences for bug finding.

Ask the reviewer to assume the relevant behavior is wrong, trace callers and failure paths, and return `path:line: severity: problem and fix`. Severity is bug, risk, nit or q. A clean result names what was checked and its limits. Reviewers never edit or post findings.

Triage each finding: fix it, reject it with a specific evidence-based reason, or escalate a real product decision. Record consequential rejected findings in the existing task state and, when publishing, the PR body. Re-review only a substantive fix that needs independent inspection; do not restart review over an unchanged diff. If review keeps introducing new blocking concerns without resolving the original question, stop and explain the blocker.
