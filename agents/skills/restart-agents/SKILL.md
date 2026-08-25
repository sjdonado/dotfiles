---
name: restart-agents
description: Restart the Claude Code or OpenCode processes running in herdr panes so they pick up a newer binary, keeping each conversation by resuming its session id. Use when an agent binary has updated and long-lived panes are still on the old version.
---

# Restart agents in herdr panes

An agent self-updates by writing a new binary and repointing a symlink. A process already running keeps the old one open, so panes that have been up since before an update stay on the previous version indefinitely. This restarts them in place without losing conversations.

## Never restart blind

Two things make this destructive, and both are cheap to avoid.

**The session running this skill is one of the panes.** Restarting it kills the conversation issuing the command, mid-turn, so it can never report back. Read `$HERDR_PANE_ID`, exclude that pane, and tell the human to restart it themselves at the end.

**A working agent loses its in-flight turn.** Restart idle panes. For anything reported as `working` or `blocked`, name it and leave it, unless the human said to take everything down.

## Find what is actually stale

Do not restart every pane. Ask each one what it is running, and compare against the installed version:

```sh
herdr agent list                      # .result.agents[] -> agent, pane_id, agent_status
herdr pane process-info --pane <id>   # foreground_processes[] entry whose argv0 is the agent
```

In that entry, `name` is the running version and `cmdline` is the exact command to relaunch. A pane already on the current version needs nothing. `claude --version` (or `opencode --version`) gives the installed one.

Keep the `cmdline` verbatim. Panes restored by herdr carry `--resume <session-id>`, which is the only reason a restart keeps the conversation, and flags like `--dangerously-skip-permissions` are part of how that pane was meant to run.

## Restart one pane

```sh
herdr pane send-keys <pane> Escape       # drop any open prompt or menu
herdr pane send-text <pane> "/exit"
herdr pane send-keys <pane> Enter
# wait for the pid from process-info to actually disappear, then:
herdr pane run <pane> "<the cmdline from process-info>"
```

Wait on the pid rather than sleeping a fixed interval, and never relaunch while the old process is alive: `pane run` types into a shell that is not at a prompt, and the command is swallowed. If the pid outlives a reasonable wait, report that pane as failed and move on. Do not escalate to a kill; a wedged agent is usually mid-write.

An agent with no `--resume` in its cmdline starts a fresh conversation. Say so before restarting it, because there is nothing to resume it back into.

## Verify, then report

Re-read `process-info` for every pane touched and confirm the version changed. Report as a table: pane, before, after, and the panes deliberately skipped with the reason (already current, working, or this session). A restart that silently produced a bare shell looks identical to success until someone opens the pane, so the verification is the deliverable, not the restart.
