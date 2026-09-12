# Verifying macos.sh

```sh
verify/macos/run.sh          # ~5 seconds
verify/macos/run.sh --keep   # leave the sandbox behind to poke at
```

It points `HOME` at a temporary directory, runs `macos.sh --links-only` twice, and asserts what landed there. Nothing is installed, nothing outside that directory is touched, and the real `$HOME` is never written to.

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

Homebrew, `mise install`, the login shell, launchd, macOS defaults, LaunchServices, and anything needing a GUI. Those are verified by running `macos.sh` for real, or by rehearsing the whole thing in a macOS VM (`tart`), which `verify/README.md` explains.
