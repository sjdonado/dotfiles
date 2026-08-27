#!/bin/sh
# Claude Code status line: model, reasoning effort, context used.
#
# Claude Code pipes a JSON payload to this on every render, so the model, effort
# and context segments are read from stdin rather than computed: `.context_window`
# already carries a pre-calculated used percentage.
#
# The MCP count is not in that payload, and nothing on disk records which servers
# actually connected, so "loaded" means enabled rather than connected: a server
# that is approved but times out still counts. Reading real connection state would
# mean spawning `claude mcp list`, which dials every server, far too slow for
# something that renders on every keystroke.
#
# total   = user-level servers + this project's own + every server the repo's
#           .mcp.json declares
# loaded  = the same, minus the .mcp.json servers still pending approval or
#           explicitly disabled
#
# So `2/4 mcp` reads as: the repo offers two more servers that have not been
# approved in this directory yet. Both numbers come from ~/.claude.json, whose
# per-project block carries enabledMcpjsonServers and disabledMcpjsonServers.
#
# No token count: Claude Code prints one above the prompt already, and that
# readout is built-in chrome with no setting behind it.
#
# No quota, neither the percentages nor the reset clocks: codexbar reports those,
# and the one line here has to stay readable at a glance.
#
# Colours come from the 16 ANSI slots, which ghostty/themes/* holds at >=4.5:1 in
# both variants. 256-cube and truecolor escapes bypass that palette and wash out,
# so they are avoided.
set -eu

payload=$(cat)

field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null || true; }

model=$(field '.model.display_name')
effort=$(field '.effort.level')
used=$(field '.context_window.used_percentage')

[ -n "$model" ] || model="claude"

# 36 cyan, 90 bright black, 32 green, 33 yellow, 31 red.
printf '\033[36m%s\033[0m' "$model"
[ -n "$effort" ] && printf '\033[90m %s\033[0m' "$effort"

if [ -n "$used" ]; then
  pct=${used%%.*}
  [ -n "$pct" ] || pct=0
  # Thresholds mirror the headroom left, not the amount spent: a run past 85%
  # is where compaction starts costing turns.
  if [ "$pct" -ge 85 ]; then colour=31
  elif [ "$pct" -ge 65 ]; then colour=33
  else colour=32
  fi
  printf '\033[90m · \033[0m\033[%sm%s%% ctx\033[0m' "$colour" "$pct"
fi

# MCP servers configured for this directory. jq over a 120KB config is ~5ms, so
# it is cheap per render; a missing or malformed file counts zero rather than
# aborting the line.
cwd=$(field '.workspace.current_dir')
[ -n "$cwd" ] || cwd=$PWD

mcp_counts=$(
  jq -r --arg dir "$cwd" '
    ((.mcpServers // {}) | length) as $user
    | ((.projects[$dir].mcpServers // {}) | length) as $project
    | ((.projects[$dir].enabledMcpjsonServers // []) | length) as $approved
    | "\($user + $project) \($approved)"
  ' "$HOME/.claude.json" 2>/dev/null || echo "0 0"
)
own=${mcp_counts%% *}
approved=${mcp_counts##* }

declared=0
if [ -f "$cwd/.mcp.json" ]; then
  declared=$(jq -r '(.mcpServers // {}) | length' "$cwd/.mcp.json" 2>/dev/null || echo 0)
fi

for n in own approved declared; do
  eval "v=\$$n"
  case "$v" in ''|*[!0-9]*) eval "$n=0" ;; esac
done

total=$((own + declared))
loaded=$((own + approved))
if [ "$total" -gt 0 ]; then
  # Amber whenever the repo declares servers this directory has not approved:
  # a tool that is silently absent is worth noticing before wondering why.
  [ "$loaded" -lt "$total" ] && colour=33 || colour=90
  printf '\033[90m · \033[0m\033[%sm%s/%s mcp\033[0m' "$colour" "$loaded" "$total"
fi

printf '\n'
