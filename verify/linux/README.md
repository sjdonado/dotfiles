# Verifying linux.sh in a container

```sh
verify/linux/run.sh                          # this Mac's architecture (aarch64)
verify/linux/run.sh --platform linux/amd64   # x86_64, emulated: slower
verify/linux/run.sh --shell                  # provision, then hand you a shell in the box
```

`run.sh` builds a bare Ubuntu 24.04 with one sudo user, copies this working tree in (uncommitted changes included), and runs `linux.sh` exactly as a box would: the pinned Determinate installer installs Nix, and `nix run .#switch` applies the home-manager configuration. Then it asserts, runs `linux.sh` a second time and asserts again. It prints `all checks passed` or what broke.

The container has no systemd, like most Coder workspaces, so this is also the check for that path: the installer sets Nix up with `--init none` and `linux.sh` starts the daemon itself.

## What it asserts

`verify.sh` holds the assertions:

- **Every declared tool runs**: `--version` answers, and each language server that has no version flag answers an LSP initialize request. OpenCode is v2.
- **Every tracked config is linked** to the file in this repository, resolved with `readlink -f`, so a copy with the same contents fails.
- **The setup steps ran**: the codex config merge, herdr's claude and OpenCode integrations, the bat theme cache.
- **Non-interactive shells resolve the tools**: a login `bash -lc`, a bare shell that sources only `~/.profile`, and `zsh -c`. This is what an agent hook, a herdr pane running a command and `ssh host command` get. `claude` must resolve to the Nix profile, not to a binary an old installer left in `~/.local/bin`.
- **The tracked git identity wins** over an injected `GIT_AUTHOR_EMAIL`, which is what Coder sets.

`run.sh` adds the run-level assertions: the herdr plugin step reported itself skipped (no server runs in the container), and the second run kept the same home-manager generation, left no new backup files, duplicated no shell block and did not reinstall Nix.

## What it does not cover

macOS: see `verify/README.md`. Nor does it prove the box is usable in anger: nothing authenticates, no agent runs a session, herdr never starts a server. It proves provisioning is complete, linked, idempotent and on PATH.
