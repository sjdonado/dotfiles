#!/usr/bin/env bash
# Entrypoint for the git-bug overlay: run termui only where it is safe to.
#
# termui's first-run prompt creates an identity when none is active, and the next
# `git bug push` publishes it, so a repo without an active identity gets a message
# instead. Outside a git repo termui would exit at once and leave a blank overlay.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  msg="git-bug: $(pwd) is not a git repository."
elif ! command -v git-bug >/dev/null 2>&1; then
  msg="git-bug is not installed (macOS only: mise.toml declares brew:git-bug)."
elif ! err=$(git bug user show 2>&1 >/dev/null); then
  # The same command also fails while another process holds git-bug's lock, so only
  # the no-identity error gets the identity hint; anything else is shown as is.
  case "$err" in
    *"No identity is set"*) msg="git-bug: no active identity here. Adopt or create one first: git bug user adopt <id>, or git bug user new --non-interactive." ;;
    *) msg="git-bug: $err" ;;
  esac
else
  exec git bug termui
fi
printf '%s\n\nPress any key to close.\n' "$msg"
# Read the key from the terminal, so a closed stdin cannot dismiss the message unseen.
read -r -n 1 -s </dev/tty 2>/dev/null || sleep 5
exit 0
