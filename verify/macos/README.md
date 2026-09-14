# Verifying macos.sh

```sh
verify/macos/run.sh          # ~5 seconds
verify/macos/run.sh --keep   # leave the sandbox behind to poke at
```

It stages a copy of the working tree (no `.git`) in `/tmp`, creates an ephemeral local user that owns it, and runs `macos.sh --links-only` twice as that user plus the assertions. Nothing is installed. The real `$HOME` is unreachable by file permission, not just by `$HOME` pointing elsewhere: the sandbox lives outside the per-user `/var/folders` tree (whose parents are 700) and is itself 700 and user-owned. User and sandbox are deleted afterwards; `--keep` leaves both and prints their removal commands. Needs sudo once, for user create/delete.

## What `--links-only` means

The half of `macos.sh` that only writes inside `$HOME`: directories, symlinks, and generated config. It skips, and says it is skipping, every block that changes the machine: the login shell and `/etc/shells`, macOS `defaults`, app shortcuts, `duti` default-app bindings, the launchd agents, BrowserRouter, herdr plugin linking, and moshi-hook pairing. `--install` is not implied and Homebrew is never invoked.

The flag exists for this check. A sandboxed run of the whole script would `chsh` a real user and load real launch agents, which is not a test, it is an accident.

## What it asserts

- Every tracked config is a **symlink** resolving to the file in this repository, compared with `readlink -f` on both sides so a copy with the same contents fails.
- Generated files that are deliberately not links exist anyway: `~/.codex/config.toml`, `~/.fish_history`.
- `~/.local/bin` holds a link per file in `bin/`, and no dangling link from a script this repo has since removed.
- The skipped blocks really were skipped: no launch agent plist, no browser-router config.
- **The second run replaces nothing.** A first run legitimately produces one backup, because `herdr integration install claude` writes a real `~/.claude/settings.json` before the tracked one is linked over it, which is why that install runs first. The second run must add no backup at all: if it does, `link_managed` is replacing a link it already owns, and every future provisioning run would litter `.backup.<timestamp>` files next to the real config.

## What it cannot cover

Homebrew, `mise install`, the login shell, launchd, macOS defaults, LaunchServices, and anything needing a GUI. Those are verified by running `macos.sh` for real. A disposable-VM rehearsal exists in `verify/macos-vm/` but is deferred: host vmnet NAT died under brew-download load (pristine guests fail identically, so the rehearsal wedged nothing) and needs a host reboot to recover.
