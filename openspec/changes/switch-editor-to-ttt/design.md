## Context

See proposal.md for motivation. Two things in this repo's history constrain the design and must not be rediscovered by trial and error.

**Terminal graphics only reach the outer terminal.** Measured in this repo (PR #7, closed): chawan renders mermaid PNGs and wraps table cells correctly when it runs as its own Ghostty pane, and renders the same page with a blank gap where the image belongs when it runs inside Neovim's `:terminal`, in a split and full-screen alike. Neovim's libvterm consumes the Kitty graphics protocol. The rule generalizes: an image-capable program must be a direct child of the outer terminal, never nested inside another terminal emulator. It is the first thing any future in-editor rendering has to contend with.

**Ghostty has a display budget well below its transmit limit, and it shrinks as the window grows.** Also measured here: Ghostty accepted a 66 MB decoded image over the wire but silently failed to display a 24 MB diagram in a 56-row tab that displayed fine in a 33-row split, answering ENOMEM above roughly 66 MB. A mermaid render sized naively at three times the terminal scale produced a blank diagram. The render must therefore be capped by a decoded-size budget, not by a fixed scale multiplier.

**The prior art is recoverable if it is ever wanted again.** A working standalone reader exists at `nvim/bin/md-preview`, commit `5c6e2c0` on the closed branch `feat/nvim-markdown-browser`, and a hardened version of it at `660215f` on this change's own branch. Both were rejected as a shipping surface: see Rejected approach below.

## Goals / Non-Goals

Goals: one editor for reading, diffing, and git; identical provisioning from tracked config on macOS and Linux; a materially smaller dependency tree.

Non-Goals: replacing the agent harness or anything under `agents/`, `bench/`, and `openspec/`; making TTT render images (see Deferred work); shipping any image-capable markdown reader in this change; preserving Neovim as a configured editor; a heavy editing setup. Modal editing power is deliberately given up, because the human does not hand-write code.

## Decisions

1. **TTT config lives in the repo and is symlinked, matching every other tool here.** Track `ttt/settings.json` (and `ttt/keybindings.json` or `ttt/themes/` if a preference ever needs them) and link each tracked file into `~/.config/ttt/` with the installers' existing `link_managed` helper. TTT reads `~/.config/ttt/` as user overrides over its bundled defaults, and honors `TTT_CONFIG_DIR` for isolated sessions. Alternative rejected: configuring TTT by hand per machine, which is the problem this repo exists to solve.

   Link the files, not the directory: TTT keeps `plugins.ttt.json` and `plugins/` in that same directory and rewrites them as plugins are installed or toggled, so linking the directory would land plugin state in this repository. Note also that `SaveSettings` is a plain `os.WriteFile` that follows the symlink, so a settings change made in TTT's own UI rewrites the tracked file with the complete key set and overwrites tracked values rather than merging with them. The tracked file is therefore a full snapshot, not a minimal override set.

2. **Provision TTT from its brew tap on macOS; on Linux, install from the project's own release or `go install`.** `brew info eugenioenko/ttt/ttt` reports stable 1.5.0. There is no apt package, so linux.sh follows the pattern already used for worktrunk and moshi-hook: attempt the documented install, and on failure print a one-line notice rather than aborting provisioning.

3. **Plugin provisioning is verified before it is promised.** TTT installs plugins through its Plugins sidebar or an "install from URL" command, which is imperative rather than declarative. The implementing agent must determine whether a plugin can be installed non-interactively (a CLI subcommand or a path under `~/.config/ttt/`) before adding any plugin to the installers. If it cannot, record that plugins are a manual post-install step in the README and do not fake it in a script.

4. **The theme pair is `default-dark` and `default-light`.** TTT has no automatic dark/light switching: settings carry a single `theme` string, there is no background-color query anywhere in its source, and switching is the manual `theme.switch` command. Exactly one half can be tracked, and which one is not a decision worth defending: TTT rewrites `settings.json` through the symlink on every settings change, so whatever the human last chose in the UI is what the repository carries. The pair is recorded here so a later switcher knows both names.

   `transparentBackground` goes off as a consequence. Letting the terminal's background through looks right until the terminal flips to light, at which point a dark theme's light foreground sits on a light ground and is unreadable. A pinned theme painting its own background is legible in both terminal appearances; it simply does not match the flip.

5. **Additions and verification land before removals.** The task list is ordered so TTT is installed and confirmed working before Neovim, lazygit, and the herdr plugins are deleted. Removing a working editor before its replacement is proven in the human's hands is the one failure mode with no cheap recovery, and ordering it this way costs nothing. The human may take days between the two groups; the change is not abandoned mid-flight because the branch note carries the state.

6. **Keep the `neovim` binary available, stop provisioning its config.** Deleting `nvim/` removes the configured editor. Leaving the binary in the Brewfile costs nothing and leaves an escape hatch for a heavy hand-edit that TTT cannot do. Alternative rejected: removing the binary too, which would make a rare emergency edit require a reinstall.

7. **herdr keeps only what still has a host, and TTT becomes one.** `edit-tab` exists to open an nvim tab and `lazygit-panel` to open a lazygit sidebar; both go. `edit-tab` is replaced rather than simply deleted: a local `ttt-tab` plugin carries the same three-state toggle on `prefix+e`, and herdr's own `edit_scrollback` moves to `prefix+shift+e` to make room, following the precedent of `settings` moving to `prefix+,` for the lazygit panel. `lazygit-panel` and its `prefix+s` go with no replacement, since the editor is the git surface now. `panel-revive` keeps a host, because a restored TTT tab comes back as a bare shell exactly as the nvim one did, so it stays and learns the `ttt` label. `copy-ignored` is unrelated and stays.

8. **Right-clicks are routed to TTT by the plugin that opens it.** TTT's own context menu is how a pointer-driven editor is operated, and herdr's pane menu otherwise swallows every right-click. herdr has no config default for this: the plugin pane manifest has no field for it, `herdr plugin pane open` has no flag, and `ui.right_click_passthrough_modifier` only defines a modifier to hold. It is pane state, set with `herdr pane input --pane <id> --right-click pane`, so `ttt-tab` sets it on the pane it just opened and `panel-revive` re-asserts it on a restored pane. Alternative rejected: upstream's `ttt.editor` plugin, which opens TTT but cannot route right-clicks and has no toggle-back, leaving the human to pick "Send right-clicks to pane" by hand for every TTT tab.

## Risks / Trade-offs

- TTT is young, v1.5.0 with a single maintainer, so it may stall or change shape. Mitigation: a zero-config single binary operating on plain text files has near-zero lock-in, and the `neovim` binary stays installed.
- Its markdown preview plugin is third-party and text-only, so after this change nothing in the repository renders an image or a mermaid diagram in the terminal. Mitigation: none, and this is accepted deliberately. master's `glow` is text-only too, so it is not a regression; images move to Deferred work.
- Giving up modal editing is a real capability loss if the human's workflow ever shifts back to hand-writing code. Mitigation: the escape hatch above, and this change is reversible from git history.
- No automatic dark/light switching, where the retired Neovim config followed the terminal. Mitigation: none in this change; see Deferred work.

## Rejected approach: a standalone markdown reader

A `bin/mdp` command was built on this branch (`660215f`) and then dropped. It rendered mermaid fences to PNG with `mmdc`, converted with pandoc GFM, and opened the result in chawan, which draws images over the Kitty graphics protocol; it worked, and it is recoverable from git if the judgement changes.

It was rejected as not practical enough to keep. It is a second surface for a task that should live in the editor, which is the friction this change exists to reduce, and paying for it means carrying three more dependencies (chawan, pandoc, mermaid-cli, the last of which drags a headless browser) across two platforms, on one of which chawan has no package at all. Going without images until they can be attempted inside TTT is the smaller bill.

What the attempt established, and a later session should not re-derive: `mmdc --width` only sizes the layout page, so `--scale` is the only knob on output size, and it accepts fractional values below 1; a diagram's decoded size is therefore `intrinsic * scale^2`, which is what makes a decoded-size budget enforceable; and `mmdc` picks its output format from the file extension, so a promote-on-success temp file has to keep the `.png` suffix.

## Deferred work: markdown images inside TTT

The human's stated goal is one keymap inside TTT that shows a markdown preview with images, with no second surface. This change does not attempt it, and with the standalone reader dropped there is now no image-capable markdown reader in this repository at all. What a later session needs to know:

- **First measure whether TTT's embedded terminal passes Kitty graphics through.** TTT has a built-in terminal panel. If it is a real terminal emulator of its own, it will consume the graphics protocol exactly as Neovim's did. Test it with any program that draws an image in a terminal, inside that panel, before designing anything. This single measurement decides the direction and takes minutes.
- **If it passes graphics through**, a small TTT plugin that shells out to a renderer on a keybind is the whole feature, and `git show 660215f:bin/mdp` is a working renderer to start from.
- **If it does not**, the work is contributing image output to TTT itself. Contributing mermaid alone is not sufficient and is the wrong first step: TTT renders no images at all, so Kitty graphics or sixel output in its renderer comes first, and mermaid on top. That is a substantial contribution to someone else's Go codebase, worth scoping separately.
- Both Context constraints above apply to whatever gets built: graphics reach only the outer terminal, and the render must be capped by a decoded-size budget rather than a fixed scale multiplier.

## Deferred work: following the terminal's dark/light appearance

TTT cannot do it today and this change does not add it. The pieces for a later attempt are already there: `settings.reload` re-reads `settings.json` and re-applies the theme, palette and borders live with no restart, and `ttt --listen` runs an HTTP command server whose `exec` action runs any command id. So an appearance hook can rewrite the `theme` key between `default-dark` and `default-light` and tell each running instance to reload. The obstacle is that `--listen` binds one fixed port (`TTT_LISTEN_PORT` overrides it), so several concurrent instances need assigned ports and something has to track them.

## Migration Plan

Additions first, on a task branch, with the human verifying TTT in real use (laptop and iPad) before the removal group runs. Removals are a single reviewable commit range so the whole switch can be reverted with git if TTT disappoints. The README is rewritten last, once the final shape is known. The implementing agent opens one PR and never merges it.
