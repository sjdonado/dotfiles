---
name: principle-delegate-down-a-tier
description: Not a workflow; read when a step names it. What the orchestrating model keeps and what it hands to subagents. Read before spawning a subagent or running checks in a long run.
---

Not a workflow: workflows and building blocks read this when a step names it.

The capable model earns its cost on understanding the problem, settling the contract, and judging what came back. Carrying out a settled contract and running checks is mechanical. Treat yourself as the orchestrator and delegate by default; never offer the handover or stop to ask about it. The project's own `AGENTS.md` records its preference; where it records none:

- Run `verification` in a subagent one tier below the orchestrator. Hand it the contract path, the resolved ladder, and any check already known to fail for an unrelated reason, and nothing else. Keep it in this session only when the project records that, or when the handover prompt would cost more than the checks.
- Run `agent-review` reviewers at the orchestrator's tier. A reviewer too weak to find the bug is not a saving.
- Use the named skills (`verification`, `agent-review`) rather than an unnamed subagent doing the same job, so their cost is attributable. Count the reviewers a run already spawns when deciding what else to delegate.
- Delegate work, never waiting. A subagent told to watch a running process or poll returns nothing the caller could not see, and stopping it can kill what it started. A long-running command runs in the session that can see it through.
- Run preview servers through managed background shells, never detached processes (`&`, `nohup`, `disown`, `setsid`). Verify that the harness registered the shell and the server is ready before handing over its URL; otherwise report the blocker.

Concrete models and effort levels belong in the project's `AGENTS.md`, not here.
