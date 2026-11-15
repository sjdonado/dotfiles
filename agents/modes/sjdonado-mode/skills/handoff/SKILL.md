---
name: handoff
description: Preserve the current development task's essential context for another T3 agent when requested.
---

Read principle-state-outlives-the-session and update existing task state before handing off. Give the next agent the goal, settled requirements, current checkout and branch, actual verification, unresolved decisions, and next action. Reference existing diffs, notes, ADRs, and task lists instead of copying them.

Include the absolute MODE.md path and explicit activation only when the next agent is assigned to continue this development task. State allowed actions; a handoff records authority and cannot grant new authority. A new personal-agent task does not inherit the mode.

Use the host's handoff mechanism when available. If a standalone document is requested, save it outside tracked source and report its path. Do not send a message, create a thread, commit, or publish merely to prepare the handoff. Keep credentials and private user data out of it.
