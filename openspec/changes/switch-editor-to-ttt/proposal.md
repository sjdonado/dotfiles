## Why

The human no longer writes code by hand. Agents do, and the remaining need is reading: diffs before a PR, occasional file inspection, small typo fixes, and markdown design docs. Neovim is configured for an editing workload that no longer exists (a 1217-line init.lua), and its modal keymaps are actively hostile on the phone and iPad terminals the human now uses on the go. lazygit is a second tool for a job the editor can do.

TTT (Terminal Text Tool, https://github.com/eugenioenko/ttt) is a single-binary TUI editor with first-class mouse and touch support, git staging, inline and split diffs, blame, and GitHub PR review, plus a JSON config directory that this repo can symlink like every other tool. One tool replaces two and deletes the largest config in the repo.

The one thing TTT does not do is render images: its markdown preview is a community plugin and is text-only, no Kitty graphics and no sixel. That is not a regression, because the current preview on master is glow, which is also text-only, so this change is neutral on markdown and leaves the repository with no image-capable reader. A standalone reader was built and rejected: see design.md, Rejected approach. Images and mermaid diagrams are deferred until they can be attempted inside TTT itself.

## What Changes

- Add TTT: the `eugenioenko/ttt/ttt` brew tap, a tracked `ttt/` config directory (settings.json, keybindings.json, themes/) symlinked to `~/.config/ttt/`, and installer coverage on macOS and Linux.
- Remove Neovim as a configured editor: the `nvim/` tree, the neovim entries in Brewfile and linux.sh, the installer symlinks, and the `glow` binary it previewed with. Leave the `neovim` binary itself installable for emergencies but stop provisioning its config.
- Remove lazygit: Brewfile, both installers, `lazygit/config.yml`.
- Remove the herdr surfaces that exist only to host those two tools: the `edit-tab` plugin (opens an nvim tab) and its `prefix+.` keybind, the `lazygit-panel` plugin and its `prefix+s` keybind, and `panel-revive` if it has no remaining purpose once both are gone.
- Drop the nvim-specific `minimize` behavior in `bin/workspace`.
- Rewrite the README around the new shape: one editor and the agent harness.
- Record the follow-up work for rendering markdown images and mermaid inside TTT, including the terminal-graphics constraints this repo has already measured, so a later session does not rediscover them.

## Capabilities

### New Capabilities

- `editor-workspace`: one terminal editor for reading code, viewing diffs, and running git workflows, provisioned identically on every machine from tracked config.

### Modified Capabilities

None. This repository has no synced main specs yet; these deltas describe the intended behavior and are archived only after the implementing PR merges.

## Impact

Adds `ttt/`. Deletes `nvim/` and `lazygit/`. Edits Brewfile, macos.sh, linux.sh, README.md, bin/workspace, herdr/config.toml, and the herdr plugins under herdr/plugins/. Net effect is a large reduction: the 1217-line init.lua, the nvim plugin lockfile, two herdr plugins, and the glow and lazygit binaries all go, against one new binary and a JSON config file.

No agent-harness surface changes: `agents/`, `bench/`, and the skills are untouched.
