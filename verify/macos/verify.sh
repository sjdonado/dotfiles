#!/usr/bin/env bash
# Assertions for a HOME that macos.sh --links-only has just provisioned.
#
# Same four groups as the Linux container check, minus the ones a sandbox cannot
# answer: nothing is installed here, so "does every tool run" is not asked. What
# is asked is everything about linking, which is where this script's bugs live:
# a link pointing at a path that moved, a directory linked where individual files
# were meant, a file quietly replaced by a real copy.
set -uo pipefail

DOTFILES="${DOTFILES:?set DOTFILES to the repository root}"
PASS=0 FAIL=0
ok()    { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
bad()   { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
group() { printf '\n== %s\n' "$1"; }

linked() {
  local link=$1 target=$2
  if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then
    ok "${link#"$HOME"/} -> ${target#"$DOTFILES"/}"
  else
    bad "${link#"$HOME"/} is not a link to ${target#"$DOTFILES"/} (readlink: $(readlink "$link" 2>/dev/null || echo none))"
  fi
}

exists() { if [ -e "$1" ]; then ok "${1#"$HOME"/} exists"; else bad "${1#"$HOME"/} missing"; fi; }

group "tool declarations"
linked "$HOME/.config/mise/config.toml" "$DOTFILES/mise.toml"
# Silently ignored if it is not linked here: mise looks for the lock beside the
# config it resolved, not in the repository the config points at.
linked "$HOME/.config/mise/mise.lock" "$DOTFILES/mise.lock"

group "shell and terminal"
linked "$HOME/.config/fish/config.fish" "$DOTFILES/fish/config.fish"
linked "$HOME/.config/ghostty/config"   "$DOTFILES/ghostty/config"
linked "$HOME/.gitconfig"               "$DOTFILES/git/.gitconfig"
linked "$HOME/.docker/config.json"      "$DOTFILES/docker/config.json"
exists "$HOME/.fish_history"
linked "$HOME/.local/share/fish/fish_history" "$HOME/.fish_history"

group "agent harnesses"
linked "$HOME/.claude/settings.json"          "$DOTFILES/claude/settings.json"
linked "$HOME/.claude/skills"                 "$DOTFILES/agents/skills"
linked "$HOME/.claude/CLAUDE.md"              "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.agents/skills"                 "$DOTFILES/agents/skills"
linked "$HOME/.codex/AGENTS.md"               "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.config/opencode/opencode.json" "$DOTFILES/opencode/opencode.json"
linked "$HOME/.config/opencode/pty.md"           "$DOTFILES/opencode/pty.md"
linked "$HOME/.config/opencode/tui.json"      "$DOTFILES/opencode/tui.json"
linked "$HOME/.config/opencode/AGENTS.md"     "$DOTFILES/opencode/AGENTS.md"
linked "$HOME/.local/state/opencode/kv.json"  "$DOTFILES/opencode/kv.json"
exists "$HOME/.codex/config.toml"

group "bat themes"
# Linked by the shared lib/links.sh rather than by either script, so both checks
# assert them: a refactor that drops the call is otherwise invisible.
for f in "$DOTFILES/bat/themes/"*.tmTheme; do linked "$HOME/.config/bat/themes/$(basename "$f")" "$f"; done

group "editor, multiplexer, worktrees"
linked "$HOME/.config/nvim"                   "$DOTFILES/nvim"
linked "$HOME/.config/herdr/config.toml"     "$DOTFILES/herdr/config.toml"
linked "$HOME/.config/worktrunk/config.toml" "$DOTFILES/worktrunk/config.toml"

group "local bin"
for f in "$DOTFILES/bin/"*; do linked "$HOME/.local/bin/$(basename "$f")" "$f"; done
# A link this repo no longer ships must be pruned, not left dangling on PATH.
if [ -L "$HOME/.local/bin/a-command-this-repo-removed" ]; then
  bad "a stale link survived the prune"
else
  ok "no stale links in ~/.local/bin"
fi

group "nothing escaped the sandbox"
# --links-only must not have reached for the machine. These are the paths the
# skipped blocks would have written.
for escaped in "$HOME/Library/LaunchAgents/com.local.KeyRemapping.plist" \
               "$HOME/Library/LaunchAgents/com.local.TMExcludeDev.plist" \
               "$HOME/.config/browser-router/config.json"; do
  if [ -e "$escaped" ]; then bad "--links-only wrote ${escaped#"$HOME"/}"; else ok "skipped ${escaped#"$HOME"/}"; fi
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
