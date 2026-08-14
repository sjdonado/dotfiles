# Locale
set -x LC_CTYPE en_US.UTF-8
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8

# Theme settings
set -g fish_greeting ""
function fish_prompt
    set -l last_status $status
    # Prompt status only if it's not 0
    set -l stat
    if test $last_status -ne 0
        set stat (set_color red)"[$last_status]"(set_color normal)
    end
    string join '' -- (date +%s) ' ' (set_color green) (prompt_pwd) (set_color normal) $stat '> '
end

# General settings
set -g fish_history fish
set -g fish_history_max 20000
umask 002

# Path configurations
set -x EDITOR "nvim"
if test (uname) = Darwin
  set -gx PNPM_HOME "$HOME/Library/pnpm"
else
  set -gx PNPM_HOME "$HOME/.local/share/pnpm"
  set -gx COREPACK_HOME "$HOME/.cache/corepack"
end

# Herdr is the source of truth inside panes, and herdr-theme-mode reads its OSC 11
# answer. This gives every process started in the pane a correct value to begin with.
#
# It is not the whole story. Claude Code, OpenCode and Neovim all follow a flip in an
# already-running session when toggling from the Moshi client, observed directly. For
# Claude that has no explanation in terms of this variable, since no OSC 11 sequence
# appears anywhere in its binary. The same flip under Ghostty does not propagate, so
# the gap is on the client side rather than here. Do not add a settings.json writer
# for it; that was tried and reverted.
#
# OpenCode queries OSC 11 itself and treats this variable as the fallback, which is
# what saves it when the query goes unanswered.
#
# Neovim is the exception: it queries at startup and handles unsolicited responses
# via TermResponse, and nvim/init.lua re-queries on FocusGained.
set -l herdr_theme_mode
if set -q HERDR_ENV
  set herdr_theme_mode ("$HOME/.config/dotfiles/bin/herdr-theme-mode" 2>/dev/null)
  if test "$herdr_theme_mode" = dark
    set -gx COLORFGBG "15;0"
  else if test "$herdr_theme_mode" = light
    set -gx COLORFGBG "0;15"
  else
    set -e COLORFGBG
  end
end

# bat follows Herdr inside a pane and the local system elsewhere.
if test "$herdr_theme_mode" = dark
  set -gx BAT_THEME GitHub-Dark
else if test "$herdr_theme_mode" = light
  set -gx BAT_THEME GitHub-Light
else if test (uname) = Darwin
  # In light mode the AppleInterfaceStyle key does not exist, so the substitution
  # is empty. Capture it first: an unquoted empty substitution would leave test(1)
  # with a missing argument, and fish does not expand (cmd) inside double quotes.
  set -l macos_appearance (defaults read -g AppleInterfaceStyle 2>/dev/null)
  if test "$macos_appearance" = Dark
    set -gx BAT_THEME GitHub-Dark
  else
    set -gx BAT_THEME GitHub-Light
  end
else
  set -gx BAT_THEME GitHub-Dark
end
set -x PATH $HOME/.cargo/bin $PATH

# Add custom man pages
if set -q MANPATH
    set -x MANPATH "$HOME/.config/dotfiles/man:$MANPATH"
else
    set -x MANPATH "$HOME/.config/dotfiles/man:"
end

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.opencode/bin"
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin

fish_add_path "$HOME/.bun/bin"
fish_add_path "$PNPM_HOME"
fish_add_path "$HOME/go/bin"
fish_add_path "$HOME/Library/Android/sdk/platform-tools"

# Aliases
alias python=/usr/bin/python3
alias wtc="wt switch --create --no-cd"
alias wtr="wt remove -D --force"
alias wtl="wt list --full"
# Create a worktree and hand the terminal straight to an agent. -x replaces the
# wt process after pre-start provisioning, so the agent gets a full TTY.
#   wty my-branch -- '/yolo fix the thing'
alias wty="wt switch --create -x claude --"
alias wtp="wt step prune --min-age 7d --dry-run"

# Keymaps
bind \e 'toggle_vi_mode; commandline -f repaint'
bind \cf fzf_git_repos

# Source external variables
test -f "$HOME/.config/dotfiles/.env"; and . "$HOME/.config/dotfiles/.env"

# Coder writes the workspace session env (STRIPE_API_KEY, OP_SERVICE_ACCOUNT_TOKEN,
# GIT_ASKPASS, …) as POSIX sh for shells its agent did not spawn. herdr panes
# start fish directly, so ~/.zshrc never sources it and those vars go missing:
# `stripe listen` then silently falls back to its interactive login flow. The
# file is real script (loops, case), so run it in sh and import the result.
if test -f "$HOME/.config/coder/env.sh"
    for line in (sh -c '. "$HOME/.config/coder/env.sh" >/dev/null 2>&1; env' 2>/dev/null)
        set -l kv (string split -m 1 -- = $line)
        test (count $kv) -eq 2; or continue
        contains -- $kv[1] PWD OLDPWD SHLVL _; and continue
        set -gx $kv[1] $kv[2]
    end
end

# Coder also injects a git identity (juan@autarc.energy) into every process it
# spawns, and env beats ~/.gitconfig, so every commit made here ignored the
# tracked user.name/user.email. Drop the identity vars and let gitconfig decide.
# GIT_ASKPASS and GIT_SSH_COMMAND stay: those are how Coder brokers git auth.
set -e GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# No core dumps. kernel.core_pattern is the bare name `core`, so a crash writes
# the dump into the process's cwd: a SIGABRT in the Sentry MCP server left a
# 5.3G core.<pid> sitting in the repo it was started from.
ulimit -c 0

# The Claude and OpenCode hooks report to this daemon over a Unix socket; with
# it down they write into nothing and the phone stays silent. macOS runs it via
# `brew services`, but a Coder workspace has no systemd user bus, so the first
# interactive shell after a rebuild brings it up. disown keeps it alive when the
# pane that started it closes.
if status is-interactive; and command -q moshi-hook
    if not pgrep -x moshi-hook >/dev/null 2>&1
        moshi-hook serve >/dev/null 2>&1 &
        disown
    end
end

command -q rbenv; and status --is-interactive; and rbenv init - --no-rehash fish | source
test -f "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
