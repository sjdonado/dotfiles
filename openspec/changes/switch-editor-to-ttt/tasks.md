## 0. Orientation

- [x] 0.1 Read design.md in full before editing anything. It records two measured constraints (terminal graphics only reach the outer terminal; Ghostty's display budget is far below its transmit limit) that will otherwise be rediscovered the hard way.
- [x] 0.2 Recover the prior art: `git show 5c6e2c0:nvim/bin/md-preview`. Superseded, see task 2: the standalone reader was built, then dropped.
- [x] 0.3 Branch from master; never work on master. Preserve the pre-existing dirty files `agents/skills/tldraw-offline/SKILL.md` and `claude/settings.json` (both are rewritten by their own apps) and the stray `nvim/nvim-pack-lock.json` entries; none are part of this change.

## 1. Add TTT

- [x] 1.1 Add the `eugenioenko/ttt/ttt` brew tap and formula to the Brewfile.
- [x] 1.2 Create the tracked `ttt/` config directory with `settings.json`, `keybindings.json`, and `themes/` as needed, holding the human's preferences rather than an empty scaffold. Keep it minimal; TTT ships defaults and only overrides belong here.
- [x] 1.6 Record the theme pair `default-dark` / `default-light` in design.md Decision 4 and turn `transparentBackground` off. Which half the config carries is not tracked as a decision: TTT rewrites `settings.json` through the symlink, so it is whatever was last chosen in its UI.
- [x] 1.3 Link `ttt/` to `~/.config/ttt/` in macos.sh and linux.sh with the existing `link_managed` helper, matching how `agents/AGENTS.md` is linked.
- [x] 1.4 Install TTT on Linux from its release or `go install`, following the existing pattern for tools with no apt package: attempt, and on failure print one notice without aborting.
- [x] 1.5 Determine whether TTT plugins can be installed non-interactively (per design.md Decision 3). If they can, provision the markdown-preview plugin; if they cannot, document it as a manual post-install step in the README and add nothing to the installers.

## 2. Drop the markdown reader

The standalone reader was built (`660215f`) and then rejected as not practical; see design.md, Rejected approach. Images and mermaid are deferred until they can be attempted inside TTT.

- [x] 2.1 Delete `bin/mdp` and remove its symlink from `~/.local/bin`.
- [x] 2.2 Remove chawan and pandoc from the Brewfile, pandoc from the linux.sh apt list, the linux.sh chawan notice, and the mermaid-cli install from both installers.
- [x] 2.3 Remove the README's markdown-reading section.
- [x] 2.4 Keep the measured terminal-graphics constraints in design.md. They are what the deferred in-TTT work starts from, and they cost nothing to retain.

## 3. Confirm before removing anything

- [ ] 3.1 Stop and hand back to the human with TTT installed and working. They use it in real work, on the laptop and on a tablet, and confirm before the removals below. Do not proceed on your own judgment; removing a working editor before its replacement is proven is the one step with no cheap recovery.

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

- [ ] 7.1 Describe the new shape: TTT as the single editor for reading, diffs, and git; the agent harness unchanged; no image-capable markdown reader, deliberately.
- [ ] 7.2 Remove the nvim and lazygit sections, and state the manual step for TTT plugins if task 1.5 found they cannot be provisioned.
- [ ] 7.3 Record both deferred goals, markdown images inside TTT and dark/light switching, pointing at design.md's Deferred work sections so the next session starts from the measurement rather than a guess.

## 8. Validate and hand off

- [ ] 8.1 Run the repository's checks: `sh -n macos.sh`, `bash -n linux.sh`, `ruby -c Brewfile`, JSON parse of every file under `ttt/`, `git diff --check HEAD`, and `openspec validate switch-editor-to-ttt --strict`.
- [ ] 8.2 Confirm a provisioning dry run does not reference a deleted path, and that no remaining file points at `nvim/` or `lazygit/`.
- [ ] 8.3 Run `adversarial-review` on the accumulated diff and triage every finding.
- [ ] 8.4 Commit per `caveman-commit` with additions and removals as separate, revertable commit ranges. Open one PR whose body states what was removed, the dependency count before and after, the confirmed verification, and the deferred work. Never merge.
