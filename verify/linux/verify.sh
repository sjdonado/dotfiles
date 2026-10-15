#!/usr/bin/env bash
# Assertions for a box linux.sh has provisioned. Run inside the container, after the script. Prints every result, then exits non-zero if any failed, so a failure says which kind of breakage it is: a missing tool, a config that is not linked, a shell that cannot find the tools, or an identity that is wrong.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"
PASS=0 FAIL=0
ok()   { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
group() { printf '\n== %s\n' "$1"; }

# A tool counts as installed only if it runs: a wrapper whose setup never happened is on PATH and still broken. Some tools spell the version flag differently, hence the optional second argument.
runs() {
  local cmd=$1 flag=${2:---version} out
  if ! command -v "$cmd" >/dev/null 2>&1; then bad "$cmd not on PATH"; return; fi
  if out=$("$cmd" $flag 2>&1 </dev/null) && [ -n "$out" ]; then
    ok "$cmd -> $(printf '%s' "$out" | head -1 | cut -c1-50)"
  else
    bad "$cmd on PATH but '$cmd $flag' failed: $(printf '%s' "$out" | head -1 | cut -c1-60)"
  fi
}

# The link has to resolve to the file in the working tree: a copy with the same contents fails.
linked() {
  local link=$1 target=$2
  if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then
    ok "${link#"$HOME"/} -> ${target#"$DOTFILES"/}"
  else
    bad "${link#"$HOME"/} is not a link to ${target#"$DOTFILES"/} (readlink -f: $(readlink -f "$link" 2>/dev/null || echo none))"
  fi
}

group "Nix"
# Upstream Nix, not Determinate Nix: nix-darwin manages nix.conf on macOS, and both platforms install the same way.
if v=$(nix --version 2>&1) && ! grep -qi determinate <<<"$v"; then ok "upstream Nix: $v"; else bad "not upstream Nix: $v"; fi

group "declared tools"
for c in git fish mosh python3 pip wget rg fd bat fzf jq lazygit nvim tree-sitter wt node bun pnpm uv claude codex opencode openspec agent-browser herdr; do runs "$c"; done
if opencode --version 2>/dev/null | grep -q 'v2\.'; then ok "OpenCode is v2"; else bad "OpenCode is not v2 ($(opencode --version 2>&1 | head -1))"; fi

group "language servers and formatters (from Nix, not Mason)"
for c in astro-ls basedpyright clangd crystalline lua-language-server vtsls yaml-language-server black gofumpt isort prettierd ruff stylua; do runs "$c"; done
runs gopls version
# These servers have no version flag; each has to answer an LSP initialize request with its capabilities. They run in parallel, since each needs a few seconds to answer.
initialize='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'
# Captured before matching: under pipefail, the server's exit status after stdin closes would override grep's.
answers() {
  local out
  out=$({ printf 'Content-Length: %d\r\n\r\n%s' "${#initialize}" "$initialize"; sleep 5; } | timeout 15 "$1" --stdio 2>/dev/null)
  grep -q '"capabilities"' <<<"$out"
}
lsp_dir=$(mktemp -d)
for c in vscode-css-language-server vscode-eslint-language-server vscode-json-language-server svelteserver tailwindcss-language-server; do
  { if answers "$c"; then echo "ok"; else echo "fail"; fi > "$lsp_dir/$c"; } &
done
wait
for f in "$lsp_dir"/*; do
  c=$(basename "$f")
  if [ "$(cat "$f")" = ok ]; then ok "$c answers an LSP initialize request"; else bad "$c does not answer an LSP initialize request"; fi
done
rm -rf "$lsp_dir"
for c in golangci-lint-langserver goimports; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c on PATH (has no version flag)"; else bad "$c not on PATH"; fi
done
if nvim --headless -c 'if v:errmsg != "" | cquit 1 | endif' -c 'qa' >/dev/null 2>&1; then ok "nvim starts headless without errors"; else bad "nvim reports errors on a headless start"; fi

group "agent-browser's Chrome"
if [ "$(uname -m)" = aarch64 ]; then
  printf '  skip Chrome for Testing has no linux/arm64 build\n'
elif ls -d "$HOME"/.agent-browser/browsers/chrome-* >/dev/null 2>&1; then
  ok "Chrome downloaded to ~/.agent-browser/browsers"
else
  bad "agent-browser install left no Chrome in ~/.agent-browser/browsers"
fi

group "linked config"
linked "$HOME/.gitconfig"                       "$DOTFILES/git/.gitconfig"
linked "$HOME/.config/fish/config.fish"         "$DOTFILES/fish/config.fish"
for f in "$DOTFILES/fish/functions/"*; do linked "$HOME/.config/fish/functions/$(basename "$f")" "$f"; done
linked "$HOME/.config/ghostty/config"           "$DOTFILES/ghostty/config"
for f in "$DOTFILES/ghostty/themes/"*; do linked "$HOME/.config/ghostty/themes/$(basename "$f")" "$f"; done
for f in "$DOTFILES/bat/themes/"*; do linked "$HOME/.config/bat/themes/$(basename "$f")" "$f"; done
for f in "$DOTFILES/bin/"*; do linked "$HOME/.local/bin/$(basename "$f")" "$f"; done
linked "$HOME/.config/nvim"                     "$DOTFILES/nvim"
linked "$HOME/.config/herdr/config.toml"        "$DOTFILES/herdr/config.toml"
linked "$HOME/.config/worktrunk/config.toml"    "$DOTFILES/worktrunk/config.toml"
linked "$HOME/.config/zed/settings.json"        "$DOTFILES/zed/settings.json"
linked "$HOME/.config/zed/keymap.json"          "$DOTFILES/zed/keymap.json"
linked "$HOME/.claude/settings.json"            "$DOTFILES/claude/settings.json"
linked "$HOME/.claude/skills"                   "$DOTFILES/agents/skills"
linked "$HOME/.claude/CLAUDE.md"                "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.agents/skills"                   "$DOTFILES/agents/skills"
linked "$HOME/.codex/AGENTS.md"                 "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.config/opencode/opencode.json"   "$DOTFILES/opencode/opencode.json"
linked "$HOME/.config/opencode/cli.json"        "$DOTFILES/opencode/cli.json"
linked "$HOME/.config/opencode/AGENTS.md"       "$DOTFILES/opencode/AGENTS.md"
linked "$HOME/.config/opencode/plugins/no-foreground-wait.ts" "$DOTFILES/opencode/plugins/no-foreground-wait.ts"
linked "$HOME/.local/state/opencode/kv.json"    "$DOTFILES/opencode/kv.json"
linked "$HOME/.pi/agent/settings.json"          "$DOTFILES/pi/settings.json"
linked "$HOME/.pi/agent/mcp.json"               "$DOTFILES/pi/mcp.json"
linked "$HOME/.pi/agent/AGENTS.md"              "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.agent-browser/config.json"       "$DOTFILES/agent-browser/config.json"
linked "$HOME/.local/share/fish/fish_history"   "$HOME/.fish_history"

group "generated by the setup steps"
if [ -f "$HOME/.codex/config.toml" ]; then ok "codex-config wrote ~/.codex/config.toml"; else bad "~/.codex/config.toml missing"; fi
if [ -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then ok "herdr's claude hook is installed"; else bad "herdr's claude hook is missing"; fi
if [ -f "$HOME/.config/opencode/herdr-opencode/tui.js" ] && [ -f "$HOME/.config/opencode/plugins/herdr-agent-state.js" ]; then
  ok "herdr's OpenCode integration is installed"
else
  bad "herdr's OpenCode integration is incomplete"
fi
if bat --list-themes 2>/dev/null | grep -q '^GitHub-Dark'; then ok "bat resolves the GitHub-Dark theme from its cache"; else bad "bat cache lacks GitHub-Dark"; fi

group "non-interactive shells resolve the tools"
# This is the shell an agent hook or a herdr pane running a command gets: no rc file beyond what these read.
for c in rg nvim wt codex claude; do
  if bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
  # `ssh host command` runs a non-login, non-interactive bash, which reads only ~/.bashrc, up to its interactive guard.
  if env -i HOME="$HOME" bash -c ". ~/.bashrc >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then ok "a non-login bash sourcing ~/.bashrc finds $c"; else bad "~/.bashrc does not put $c on PATH before its interactive guard"; fi
  if env -i HOME="$HOME" bash -c ". ~/.profile >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then
    ok "a bare shell sourcing ~/.profile finds $c"
  else
    bad "~/.profile does not put $c on PATH"
  fi
  # zsh comes from the Nix profile (Ubuntu has none), so it is named by path: env -i leaves no PATH to find it with.
  if env -i HOME="$HOME" "$HOME/.nix-profile/bin/zsh" -c "command -v $c" >/dev/null 2>&1; then ok "zsh -c finds $c (via ~/.zshenv)"; else bad "zsh -c cannot find $c"; fi
done
if [ "$(env -i HOME="$HOME" bash -lc 'command -v claude')" = "$HOME/.nix-profile/bin/claude" ]; then
  ok "claude resolves to the Nix profile, ahead of ~/.local/bin"
else
  bad "claude resolves to $(env -i HOME="$HOME" bash -lc 'command -v claude'), not the Nix profile"
fi
if fish -c 'type -q rg; and type -q nvim' 2>/dev/null; then ok "fish finds rg and nvim"; else bad "fish cannot find rg or nvim"; fi

group "git identity comes from the tracked gitconfig"
tracked=$(git config -f "$DOTFILES/git/.gitconfig" user.email)
if [ -n "$tracked" ] && env GIT_AUTHOR_EMAIL=injected@coder bash -lc 'git var GIT_AUTHOR_IDENT' 2>/dev/null | grep -qF "<$tracked>"; then
  ok "an injected GIT_AUTHOR_EMAIL gives way to the tracked user.email"
else
  bad "the login shell does not use the tracked user.email ($tracked)"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
