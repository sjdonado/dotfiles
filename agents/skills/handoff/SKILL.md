---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace. This document is not the branch note: durable state belongs at `.agent/<branch-key>.md` and the work list at `.agent/<branch-key>.tasks.md`, both described in `AGENTS.md`, and neither of those moves to the temporary directory.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

The same holds for the task list, which is what the next session needs most: name its path rather than restating it. That is the OpenSpec change's `tasks.md` where one exists, and otherwise the session task list at `.agent/<branch-key>.tasks.md` described in `AGENTS.md`. Make sure it is current before writing the handoff, since the handoff is a pointer to it and a stale list is worse than none.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
