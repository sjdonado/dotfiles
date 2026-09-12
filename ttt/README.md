# TTT

Editor configuration for [TTT](https://github.com/eugenioenko/ttt). `settings.json` here is linked file by file into `~/.config/ttt/`. See the Text editor section of the repository README for how it is launched and linked.

## How it works

Syntax highlighting is chroma, compiled into the binary, so there are no parsers to build and nothing like `tree-sitter` or Mason to keep current. The outline and symbol list come from LSP (`textDocument/documentSymbol`), so they appear only for languages with a server configured under `lsp.servers`; highlighting does not depend on that.

Startup, five runs through a real pty so the UI attaches (`script -q /dev/null ttt --exec "quit" .`, Apple M5, macOS 25.5, 2026-09-11): 20-60 ms, median 20 ms. A single Go binary with no plugin manager, so there is nothing that grows with use: startup stays flat as the editor gets configured. On disk it is 14 MB and configures itself from one JSON file, with no plugin tree, no language-server package manager and no per-language parsers underneath it.

## What it does not do

- **No image or mermaid rendering.** TTT draws no images, so nothing here renders a diagram in the terminal. Doing it outside the editor costs chawan, pandoc and a headless-browser mermaid CLI on both platforms, which is more than it is worth.
- **No automatic dark/light switching.** TTT carries one `theme` string with no appearance query, so the theme is whatever was last chosen with Switch Theme. The pair is `default-dark` and `default-light`.

## Deferred

Both are written up in `openspec/changes/switch-editor-to-ttt/design.md` so the next attempt starts from the measurement rather than a guess:

- **Markdown images and mermaid inside TTT.** TTT renders no images at all, so its markdown preview plugin is text-only. The first thing to measure is whether TTT's embedded terminal passes the Kitty graphics protocol through, since a nested terminal emulator eats it; that single test decides whether this is a plugin or a contribution to TTT's renderer.
- **Following the terminal's dark/light appearance.** TTT carries one `theme` string and no appearance query. `settings.reload` re-applies a theme live and `ttt --listen` accepts commands over HTTP, so an appearance hook could drive it; the obstacle is that `--listen` binds one fixed port, so several instances need assigned ports.
