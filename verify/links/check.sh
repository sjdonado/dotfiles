#!/usr/bin/env bash
# Exercise shared agent linking and guarded integration installation in a disposable HOME.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-agent-links.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home" CODEX_HOME="$SANDBOX/home/.codex"
export HERDR_TEST_LOG="$SANDBOX/herdr-calls.log"
mkdir -p "$HOME/.config/opencode" "$HOME/.claude/hooks" "$SANDBOX/bin"
touch "$HOME/.claude/hooks/herdr-agent-state.sh"
cat > "$SANDBOX/bin/herdr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$HERDR_TEST_LOG"
[ "$*" = 'integration install opencode' ] || exit 2
[ "${HERDR_TEST_FAIL:-0}" = 0 ] || exit 42
mkdir -p "$HOME/.config/opencode/herdr-opencode" "$HOME/.config/opencode/plugins"
printf '// generated client\n' > "$HOME/.config/opencode/herdr-opencode/tui.js"
printf '// generated server\n' > "$HOME/.config/opencode/plugins/herdr-agent-state.js"
EOF
chmod +x "$SANDBOX/bin/herdr"
export PATH="$SANDBOX/bin:$PATH"
for obsolete in pty.md pty-v2 tui.json; do
  ln -s "$ROOT/opencode/$obsolete" "$HOME/.config/opencode/$obsolete"
done
printf 'user data\n' > "$HOME/.config/opencode/user-data.txt"
cd "$ROOT"
. "$ROOT/lib/links.sh"
INSTALL=1
link_agent_configs > "$SANDBOX/first.log" 2>&1
for obsolete in pty.md pty-v2 tui.json; do
  [ ! -L "$HOME/.config/opencode/$obsolete" ] || { printf 'FAIL: owned %s link remains\n' "$obsolete"; exit 1; }
done
printf 'PASS: repository-owned legacy links are removed\n'
[ -f "$HOME/.config/opencode/herdr-opencode/tui.js" ] && [ -f "$HOME/.config/opencode/plugins/herdr-agent-state.js" ]
printf 'PASS: shared linking installs Herdr integration\n'
printf 'local PTY notes\n' > "$HOME/.config/opencode/pty.md"
printf '{}\n' > "$SANDBOX/local-tui.json"
ln -s "$SANDBOX/local-tui.json" "$HOME/.config/opencode/tui.json"
INSTALL=0
calls_before=$(wc -l < "$HERDR_TEST_LOG")
link_agent_configs > "$SANDBOX/second.log" 2>&1
[ "$(wc -l < "$HERDR_TEST_LOG")" = "$calls_before" ]
printf 'PASS: linking without installation does not run Herdr installers\n'
grep -q 'local PTY notes' "$HOME/.config/opencode/pty.md"
[ "$(readlink "$HOME/.config/opencode/tui.json")" = "$SANDBOX/local-tui.json" ]
grep -q 'user data' "$HOME/.config/opencode/user-data.txt"
printf 'PASS: unrelated local files and links survive a second run\n'
INSTALL=1
export HERDR_TEST_FAIL=1
link_agent_configs > "$SANDBOX/failed-install.log" 2>&1
grep -q 'Herdr integration failed; re-run: herdr integration install opencode' "$SANDBOX/failed-install.log"
printf 'PASS: failed Herdr installation is reported\n'
