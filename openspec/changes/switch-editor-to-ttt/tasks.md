## 0. Orientation

- [x] 0.1 Read design.md in full before editing anything. It records two measured constraints (terminal graphics only reach the outer terminal; Ghostty's display budget is far below its transmit limit) that will otherwise be rediscovered the hard way.
- [x] 0.2 Recover the prior art: `git show 5c6e2c0:nvim/bin/md-preview` from the closed branch `feat/nvim-markdown-browser`. Its shape is correct; design.md Decision 4 lists the defects to fix while promoting it.
- [x] 0.3 Branch from master; never work on master. Preserve the pre-existing dirty files `agents/skills/tldraw-offline/SKILL.md` and `claude/settings.json` (both are rewritten by their own apps) and the stray `nvim/nvim-pack-lock.json` entries; none are part of this change.

## 1. Add TTT

- [x] 1.1 Add the `eugenioenko/ttt/ttt` brew tap and formula to the Brewfile.
- [x] 1.2 Create the tracked `ttt/` config directory with `settings.json`, `keybindings.json`, and `themes/` as needed, holding the human's preferences rather than an empty scaffold. Keep it minimal; TTT ships defaults and only overrides belong here.
- [x] 1.3 Link `ttt/` to `~/.config/ttt/` in macos.sh and linux.sh with the existing `link_managed` helper, matching how `agents/AGENTS.md` is linked.
- [x] 1.4 Install TTT on Linux from its release or `go install`, following the existing pattern for tools with no apt package: attempt, and on failure print one notice without aborting.
- [x] 1.5 Determine whether TTT plugins can be installed non-interactively (per design.md Decision 3). If they can, provision the markdown-preview plugin; if they cannot, document it as a manual post-install step in the README and add nothing to the installers.

## 2. Add the markdown reader

- [x] 2.1 Add `bin/mdp` from the recovered script, fixing every defect in design.md Decision 4: percent-encode or bracket the image path, add a `sha1sum` fallback for `shasum`, correct the misleading comments, and preserve the fence source when `mmdc` is absent.
- [x] 2.2 Size the mermaid render from the terminal's pixel width clamped by a decoded-size budget, not a fixed scale multiplier.
- [x] 2.3 Ensure `chawan`, `pandoc`, and `mermaid-cli` are provisioned on both platforms: chawan and pandoc via Brewfile on macOS, pandoc via apt and chawan via a notice on Linux, mermaid-cli via bun on both.
- [ ] 2.4 Verify by running `bin/mdp` on a real design document in a Ghostty pane: a wide table wraps inside its columns and the mermaid diagram displays. Also verify a file with no mermaid fence and a path containing a space. The non-visual halves are done: a fence renders to PNG and is swapped for the image, a source path containing a space works, a file with no fence renders, a missing `mmdc` keeps the fence source, and the decoded-size clamp shrinks the render (verified with `MDP_IMAGE_BUDGET=500000`). What is left is looking at a Ghostty pane, which is the human's half of task 3.1.

## 3. Confirm before removing anything

- [ ] 3.1 Stop and hand back to the human with TTT and `bin/mdp` installed and working. They use both in real work, on the laptop and on a tablet, and confirm before the removals below. Do not proceed on your own judgment; removing a working editor before its replacement is proven is the one step with no cheap recovery.

## 4. Remove Neovim

- [ ] 4.1 Delete the `nvim/` tree (init.lua, lua/custom/, nvim-pack-lock.json, and anything else under it).
- [ ] 4.2 Remove the nvim config symlinks from macos.sh and linux.sh, and the `glow` binary from the Brewfile. Keep the `neovim` binary provisioned as an escape hatch per design.md Decision 6.
- [ ] 4.3 Drop the nvim-specific `minimize` behavior from `bin/workspace`, including its help text.

## 5. Remove lazygit

- [ ] 5.1 Remove lazygit from the Brewfile, macos.sh, and linux.sh, and delete `lazygit/config.yml`.

## 6. Remove the herdr surfaces that hosted them

- [ ] 6.1 Delete the `edit-tab` plugin and its `prefix+.` keybind from herdr/config.toml.
- [ ] 6.2 Delete the `lazygit-panel` plugin and its `prefix+s` keybind from herdr/config.toml.
- [ ] 6.3 Read `panel-revive` and decide whether anything it repairs still applies once both tools are gone. Delete it only if nothing does, and record the reason either way. Leave `copy-ignored` alone.
- [ ] 6.4 Grep the repository for remaining references to nvim, neovim, lazygit, and glow, and resolve each: `README.md`, `bin/workspace`, `fish/config.fish`, `raycast/dictation/coding-agents.txt`, and `.claude/settings.local.json` are known to mention them. A dictation wordlist entry is not a dependency; judge each on its own.

## 7. Rewrite the README

- [ ] 7.1 Describe the new shape: TTT as the single editor for reading, diffs, and git; `bin/mdp` as the markdown reader and why it is a separate pane (the outer-terminal graphics constraint); the agent harness unchanged.
- [ ] 7.2 Remove the nvim and lazygit sections, and state the manual step for TTT plugins if task 1.5 found they cannot be provisioned.
- [ ] 7.3 Record the deferred goal of previewing markdown inside TTT, pointing at design.md's Deferred work section so the next session starts from the measurement rather than a guess.

## 8. Validate and hand off

- [ ] 8.1 Run the repository's checks: `sh -n macos.sh`, `bash -n linux.sh`, `sh -n bin/mdp`, `ruby -c Brewfile`, JSON parse of every file under `ttt/`, `git diff --check HEAD`, and `openspec validate switch-editor-to-ttt --strict`.
- [ ] 8.2 Confirm a provisioning dry run does not reference a deleted path, and that no remaining file points at `nvim/` or `lazygit/`.
- [ ] 8.3 Run `adversarial-review` on the accumulated diff and triage every finding.
- [ ] 8.4 Commit per `caveman-commit` with additions and removals as separate, revertable commit ranges. Open one PR whose body states what was removed, the dependency count before and after, the confirmed verification, and the deferred in-TTT preview work. Never merge.
