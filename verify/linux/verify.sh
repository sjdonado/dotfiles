#!/usr/bin/env bash
# Assertions for a box provisioned by linux.sh. Run inside the container, after
# the script. Exits nonzero on the first failing group, and prints every result
# either way, so a failure says which of the four kinds of breakage it is:
# a missing tool, a config that is not linked, a shell that will not resolve the
# tools, or a re-run that is not idempotent.
set -uo pipefail

DOTFILES="${DOTFILES:-$HOME/.config/dotfiles}"
PASS=0 FAIL=0
ok()   { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
group() { printf '\n== %s\n' "$1"; }

runs() {
  # A tool counts as installed only if it runs: an npm wrapper whose postinstall
  # never happened is on PATH and still broken, which is exactly the failure
  # that requires an explicit build-script approval for OpenCode v2.
  local cmd=$1 out
  if ! command -v "$cmd" >/dev/null 2>&1; then bad "$cmd not on PATH"; return; fi
  if out=$("$cmd" --version 2>&1) && [ -n "$out" ]; then
    ok "$cmd -> $(printf '%s' "$out" | head -1 | cut -c1-40)"
  else
    bad "$cmd on PATH but --version failed: $(printf '%s' "$out" | head -1 | cut -c1-60)"
  fi
}

linked() {
  local link=$1 target=$2
  if [ "$(readlink -f "$link" 2>/dev/null)" = "$(readlink -f "$target" 2>/dev/null)" ] && [ -e "$link" ]; then
    ok "$link -> $target"
  else
    bad "$link is not linked to $target (readlink: $(readlink "$link" 2>/dev/null || echo none))"
  fi
}

group "tools from mise.toml"
for c in mise rg fd bat fzf jq bun pnpm uv node codex openspec agent-browser nvim tree-sitter lazygit wt opencode; do runs "$c"; done
if opencode --version 2>/dev/null | grep -q '^opencode v2\.'; then
  ok "OpenCode is v2"
else
  bad "OpenCode is not v2"
fi

group "agent-browser's Chrome"
# Chrome for Testing has no Linux ARM64 build, so there the download is expected to fail.
if [ "$(uname -m)" = aarch64 ]; then
  printf '  skip Chrome for Testing has no linux/arm64 build\n'
elif ls -d "$HOME"/.agent-browser/browsers/chrome-* >/dev/null 2>&1; then
  ok "Chrome downloaded to ~/.agent-browser/browsers"
else
  bad "agent-browser install left no Chrome in ~/.agent-browser/browsers"
fi

group "tools with their own installers"
for c in claude herdr; do runs "$c"; done

group "system packages"
for c in git fish mosh python3; do runs "$c"; done

group "linked config"
linked "$HOME/.config/mise/config.toml" "$DOTFILES/mise.toml"
# Linked separately from the config, and silently ignored if it is not: mise
# looks for the lock beside the config it resolved, not in this repository.
linked "$HOME/.config/mise/mise.lock" "$DOTFILES/mise.lock"
linked "$HOME/.pi/agent/settings.json" "$DOTFILES/pi/settings.json"
linked "$HOME/.pi/agent/mcp.json" "$DOTFILES/pi/mcp.json"
linked "$HOME/.pi/agent/AGENTS.md" "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.gitconfig"               "$DOTFILES/git/.gitconfig"
linked "$HOME/.config/fish/config.fish" "$DOTFILES/fish/config.fish"
linked "$HOME/.config/herdr/config.toml" "$DOTFILES/herdr/config.toml"
linked "$HOME/.claude/settings.json"    "$DOTFILES/claude/settings.json"
linked "$HOME/.claude/skills"           "$DOTFILES/agents/skills"
linked "$HOME/.claude/CLAUDE.md"        "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.codex/AGENTS.md"         "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.config/opencode/opencode.json" "$DOTFILES/opencode/opencode.json"
linked "$HOME/.config/opencode/cli.json" "$DOTFILES/opencode/cli.json"
if [ -f "$HOME/.config/opencode/herdr-opencode/tui.js" ] && [ -f "$HOME/.config/opencode/plugins/herdr-agent-state.js" ] && jq -e '.plugins | index("./herdr-opencode") != null' "$HOME/.config/opencode/cli.json" >/dev/null; then
  ok "Herdr's generated v2 client and server integration are installed"
else
  bad "Herdr's OpenCode integration is incomplete"
fi
linked "$HOME/.pi/agent/settings.json" "$DOTFILES/pi/settings.json"
linked "$HOME/.pi/agent/AGENTS.md"     "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.agent-browser/config.json" "$DOTFILES/agent-browser/config.json"
linked "$HOME/.config/worktrunk/config.toml"  "$DOTFILES/worktrunk/config.toml"
linked "$HOME/.config/nvim"                   "$DOTFILES/nvim"
# Linked by the shared lib/links.sh rather than by either script, so both checks
# assert them: a refactor that drops the call is otherwise invisible.
for f in "$DOTFILES/bat/themes/"*.tmTheme; do linked "$HOME/.config/bat/themes/$(basename "$f")" "$f"; done

group "non-interactive shells resolve the tools"
for rc in "$HOME/.profile" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.zshrc"; do
  if grep -Fxq 'export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/.opencode/bin:$PATH"' "$rc" && ! grep -Fxq 'export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.opencode/bin:$PATH"' "$rc"; then
    ok "${rc##*/} migrates the owned legacy PATH block"
  else
    bad "${rc##*/} still has an unmigrated owned PATH block"
  fi
done
# The reason shims are used instead of `mise activate`: this is the shell an
# agent hook or a herdr pane gets, and it sources no rc file at all.
for c in rg nvim wt codex claude; do
  if bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
  if env -i HOME="$HOME" bash -c ". ~/.profile >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then
    ok "a bare shell sourcing ~/.profile finds $c"
  else
    bad "~/.profile does not put $c on PATH"
  fi
done
if fish -c 'type -q rg; and type -q nvim' 2>/dev/null; then ok "fish finds rg and nvim"; else bad "fish cannot find rg or nvim"; fi

group "the lockfile is the one being used"
# The point of the lock is a resolve that needs no GitHub API call, which is the
# only rate-limited step in provisioning. Checked with the token removed, since
# with a token present an unlocked resolve would succeed too and prove nothing.
if out=$(env -u GITHUB_TOKEN -u GH_TOKEN mise ls --current 2>&1); then
  ok "mise resolves every tool with no GitHub token present"
else
  bad "resolving without a token failed: $(printf '%s' "$out" | tail -1 | cut -c1-80)"
fi
locked_nvim=$(grep -A3 '"github:neovim/neovim"' "$DOTFILES/mise.lock" 2>/dev/null | grep -m1 version | tr -d ' ",' | cut -d= -f2)
if [ -n "$locked_nvim" ] && nvim --version 2>/dev/null | grep -q "$locked_nvim"; then
  ok "nvim is the locked version ($locked_nvim)"
else
  bad "nvim is not the locked version (lock says '$locked_nvim', binary says '$(nvim --version 2>&1 | head -1)')"
fi

group "git identity comes from the tracked gitconfig"
if bash -lc 'git config --get user.email' 2>/dev/null | grep -q '@'; then
  ok "user.email resolves ($(bash -lc 'git config --get user.email' 2>/dev/null))"
else
  bad "user.email does not resolve"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
