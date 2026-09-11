## Context

See proposal.md for motivation. Two things in this repo's history constrain the design and must not be rediscovered by trial and error.

**Terminal graphics only reach the outer terminal.** Measured in this repo (PR #7, closed): chawan renders mermaid PNGs and wraps table cells correctly when it runs as its own Ghostty pane, and renders the same page with a blank gap where the image belongs when it runs inside Neovim's `:terminal`, in a split and full-screen alike. Neovim's libvterm consumes the Kitty graphics protocol. The rule generalizes: an image-capable program must be a direct child of the outer terminal, never nested inside another terminal emulator. This is why `mdp` is a command you run in a pane and not something embedded in an editor.

**Ghostty has a display budget well below its transmit limit, and it shrinks as the window grows.** Also measured here: Ghostty accepted a 66 MB decoded image over the wire but silently failed to display a 24 MB diagram in a 56-row tab that displayed fine in a 33-row split, answering ENOMEM above roughly 66 MB. A mermaid render sized naively at three times the terminal scale produced a blank diagram. The render must therefore be capped by a decoded-size budget, not by a fixed scale multiplier.

**The prior art is recoverable, not to be rewritten from scratch.** The working script is `nvim/bin/md-preview` at commit `5c6e2c0` on the closed branch `feat/nvim-markdown-browser`. Read it with `git show 5c6e2c0:nvim/bin/md-preview`. Its shape is correct; it has known defects listed under Decisions below.

## Goals / Non-Goals

Goals: one editor for reading, diffing, and git; identical provisioning from tracked config on macOS and Linux; markdown reading that shows tables, images, and mermaid; a materially smaller dependency tree.

Non-Goals: replacing the agent harness or anything under `agents/`, `bench/`, and `openspec/`; making TTT render images (see Deferred work); preserving Neovim as a configured editor; a heavy editing setup. Modal editing power is deliberately given up, because the human does not hand-write code.

## Decisions

1. **TTT config lives in the repo and is symlinked, matching every other tool here.** Track `ttt/settings.json`, `ttt/keybindings.json`, and `ttt/themes/` and link the directory to `~/.config/ttt/` with the installers' existing `link_managed` helper, the same way `agents/AGENTS.md` links to `~/.claude/CLAUDE.md`. TTT reads `~/.config/ttt/` as user overrides over its bundled defaults, and honors `TTT_CONFIG_DIR` for isolated sessions. Alternative rejected: configuring TTT by hand per machine, which is the problem this repo exists to solve.

2. **Provision TTT from its brew tap on macOS; on Linux, install from the project's own release or `go install`.** `brew info eugenioenko/ttt/ttt` reports stable 1.5.0. There is no apt package, so linux.sh follows the pattern already used for chawan and worktrunk: attempt the documented install, and on failure print a one-line notice rather than aborting provisioning.

3. **Plugin provisioning is verified before it is promised.** TTT installs plugins through its Plugins sidebar or an "install from URL" command, which is imperative rather than declarative. The implementing agent must determine whether a plugin can be installed non-interactively (a CLI subcommand or a path under `~/.config/ttt/`) before adding any plugin to the installers. If it cannot, record that plugins are a manual post-install step in the README and do not fake it in a script.

4. **`bin/mdp` is the markdown reader, run as a terminal pane.** It takes a markdown path, pulls each ```mermaid fence into its own file, renders each to PNG with `mmdc`, swaps the fence for an image reference, converts with `pandoc -f gfm -t html -s`, injects a small stylesheet (boxed tables so cells wrap in their column, `img { max-width: 100% }` so a diagram fits the page), and opens the result in `cha -o buffer.images=true`. The HTML path is stable per source, derived from a hash of the absolute path, so a re-run overwrites it in place and chawan's own `U` reload re-reads the same URL.

   Defects in the POC script to fix while promoting it: the mermaid image path is interpolated into markdown unescaped and breaks if the cache path contains a space, so percent-encode it or wrap it in angle brackets; `shasum` is assumed present and needs a `sha1sum` fallback for a minimal Linux; a comment claims a code background the stylesheet does not set; and the installers' "mermaid fences will show as source" message is wrong, because the fence is replaced by a broken image reference when `mmdc` is missing, so either reword it or have the script keep the fence when no PNG was produced.

   The mermaid scale must be derived from the terminal's pixel width and then clamped by a decoded-size budget, per the Ghostty finding in Context. A fixed multiple of the terminal scale is what produced a blank diagram.

5. **Additions and verification land before removals.** The task list is ordered so TTT and `mdp` are installed and confirmed working before Neovim, lazygit, and the herdr plugins are deleted. Removing a working editor before its replacement is proven in the human's hands is the one failure mode with no cheap recovery, and ordering it this way costs nothing. The human may take days between the two groups; the change is not abandoned mid-flight because the branch note carries the state.

6. **Keep the `neovim` binary available, stop provisioning its config.** Deleting `nvim/` removes the configured editor. Leaving the binary in the Brewfile costs nothing and leaves an escape hatch for a heavy hand-edit that TTT cannot do. Alternative rejected: removing the binary too, which would make a rare emergency edit require a reinstall.

7. **herdr keeps only what still has a host.** `edit-tab` exists to open an nvim tab and `lazygit-panel` to open a lazygit sidebar; both go, with their keybinds (`prefix+.` and `prefix+s`). `panel-revive` repairs panes that a server restart left as bare shells and references both tools, so the implementing agent must read it and decide whether anything it does still applies once both are gone; delete it only if nothing does. `copy-ignored` is unrelated and stays. If TTT deserves a herdr keybind of its own, that is a follow-up, not part of this change.

## Risks / Trade-offs

- TTT is young, v1.5.0 with a single maintainer, so it may stall or change shape. Mitigation: a zero-config single binary operating on plain text files has near-zero lock-in, and the `neovim` binary stays installed.
- Its markdown preview plugin is third-party and text-only, so the preview inside the editor stays weaker than `mdp`. Mitigation: `mdp` is the documented reader; the in-editor preview is a convenience at best.
- Giving up modal editing is a real capability loss if the human's workflow ever shifts back to hand-writing code. Mitigation: the escape hatch above, and this change is reversible from git history.
- Two surfaces (editor and markdown reader) instead of one is the friction the human explicitly wants gone. Mitigation: none in this change; it is the subject of Deferred work below, and it is honest to say this change does not solve it.

## Deferred work: markdown preview inside TTT

The human's stated goal is one keymap inside TTT that shows a markdown preview with images, with no second surface. This change does not attempt it. What a later session needs to know:

- **First measure whether TTT's embedded terminal passes Kitty graphics through.** TTT has a built-in terminal panel. If it is a real terminal emulator of its own, it will consume the graphics protocol exactly as Neovim's did, and running `mdp` inside TTT will show a blank gap. Test this before designing anything: render a mermaid file with `mdp`, open it in TTT's terminal panel, and look for the image. This single measurement decides the whole direction and takes minutes.
- **If TTT's terminal does pass graphics through**, a small TTT plugin that shells out to `mdp` on a keybind is the whole feature.
- **If it does not**, the options are to have the keybind launch `mdp` in a sibling terminal pane outside TTT (a herdr or multiplexer split, which keeps two surfaces but removes the manual step), or to contribute image rendering to TTT itself. Note that contributing mermaid alone is not sufficient and is the wrong first step: TTT renders no images at all, so the work is adding Kitty graphics or sixel output to its renderer first, and mermaid on top of that. That is a substantial contribution to someone else's Go codebase, worth scoping separately.
- Either way, `bin/mdp` remains the engine. Nothing in this change needs to be undone to pursue the in-editor version.

## Migration Plan

Additions first, on a task branch, with the human verifying TTT and `mdp` in real use (laptop and iPad) before the removal group runs. Removals are a single reviewable commit range so the whole switch can be reverted with git if TTT disappoints. The README is rewritten last, once the final shape is known. The implementing agent opens one PR and never merges it.
