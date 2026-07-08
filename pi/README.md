# pi

[pi](https://pi.dev) coding agent, configured to run on my Claude
subscription via [pi-claude-bridge](https://github.com/elidickinson/pi-claude-bridge).

`settings.json` symlinks to `~/.pi/agent/settings.json` (done by `bootstrap.sh`).
Defaults: provider `claude-bridge`, model `claude-opus-4-8` (1M context),
thinking level `high`.

## Install (also automated in bootstrap.sh)

```sh
curl -fsSL https://pi.dev/install.sh | sh
pi install npm:pi-claude-bridge
```

Extensions in `settings.json` `packages` auto-install on first launch.

## Auth

Uses the Claude Code subscription OAuth token (shared via the Agent SDK) —
not versioned here. `~/.pi/agent/auth.json` and Claude creds stay local.
If runs return 401, refresh the token by logging in with `claude`.
