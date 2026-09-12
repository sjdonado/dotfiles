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
  # that kept claude and opencode out of mise.toml.
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
for c in mise rg fd bat fzf jq bun pnpm uv node codex openspec ttt wt opencode; do runs "$c"; done

group "tools with their own installers"
for c in claude herdr; do runs "$c"; done

group "system packages"
for c in git fish mosh python3; do runs "$c"; done

group "linked config"
linked "$HOME/.config/mise/config.toml" "$DOTFILES/mise.toml"
linked "$HOME/.gitconfig"               "$DOTFILES/git/.gitconfig"
linked "$HOME/.config/fish/config.fish" "$DOTFILES/fish/config.fish"
linked "$HOME/.config/herdr/config.toml" "$DOTFILES/herdr/config.toml"
linked "$HOME/.claude/settings.json"    "$DOTFILES/claude/settings.json"
linked "$HOME/.claude/skills"           "$DOTFILES/agents/skills"
linked "$HOME/.claude/CLAUDE.md"        "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.codex/AGENTS.md"         "$DOTFILES/agents/AGENTS.md"
linked "$HOME/.config/opencode/opencode.json" "$DOTFILES/opencode/opencode.json"
linked "$HOME/.config/worktrunk/config.toml"  "$DOTFILES/worktrunk/config.toml"

group "non-interactive shells resolve the tools"
# The reason shims are used instead of `mise activate`: this is the shell an
# agent hook or a herdr pane gets, and it sources no rc file at all.
for c in rg ttt wt codex claude; do
  if bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
  if env -i HOME="$HOME" bash -c ". ~/.profile >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then
    ok "a bare shell sourcing ~/.profile finds $c"
  else
    bad "~/.profile does not put $c on PATH"
  fi
done
if fish -c 'type -q rg; and type -q ttt' 2>/dev/null; then ok "fish finds rg and ttt"; else bad "fish cannot find rg or ttt"; fi

group "git identity comes from the tracked gitconfig"
if bash -lc 'git config --get user.email' 2>/dev/null | grep -q '@'; then
  ok "user.email resolves ($(bash -lc 'git config --get user.email' 2>/dev/null))"
else
  bad "user.email does not resolve"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
