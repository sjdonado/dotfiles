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

# Path configurations
set -x EDITOR "nvim"
if test (uname) = Darwin
  set -gx PNPM_HOME "$HOME/Library/pnpm"
else
  set -gx PNPM_HOME "$HOME/.local/share/pnpm"
  set -gx COREPACK_HOME "$HOME/.cache/corepack"
end

# bat resolves light/dark itself: BAT_THEME=auto asks the terminal, and these two
# name which theme to use on each side. Deliberately no shell logic and no
# subprocess -- the previous version shelled out to bin/herdr-theme-mode on every
# interactive start, which cost a Python spawn plus a tty round trip per prompt.
set -gx BAT_THEME auto
set -gx BAT_THEME_DARK GitHub-Dark
set -gx BAT_THEME_LIGHT GitHub-Light

# Add custom man pages
if set -q MANPATH
    set -x MANPATH "$HOME/.config/dotfiles/man:$MANPATH"
else
    set -x MANPATH "$HOME/.config/dotfiles/man:"
end

# Nix puts its profiles first on PATH (/etc/fish, written by nix-darwin and home-manager). These come after them, so a leftover Homebrew formula or a curl-installed binary never shadows a declared tool. --path keeps them out of the universal fish_user_paths, which would put them back in front on every start.
fish_add_path --path --append "$HOME/.local/bin" "$HOME/.opencode/bin" /opt/homebrew/bin /opt/homebrew/sbin "$HOME/.bun/bin" "$PNPM_HOME" "$HOME/go/bin" "$HOME/.cargo/bin" "$HOME/Library/Android/sdk/platform-tools"

# Aliases
alias python=/usr/bin/python3
alias wtc="wt switch --create --no-cd"
alias wtr="wt remove -D --force"
alias wtl="wt list --full"
# Create a worktree and hand the terminal straight to an agent. -x replaces the
# wt process after pre-start provisioning, so the agent gets a full TTY.
#   wty my-branch -- 'use yolo to fix the thing'
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

# Coder also injects a git identity (the workspace owner's work email) into
# every process it spawns, and env beats ~/.gitconfig, so every commit made here ignored the
# tracked user.name/user.email. Drop the identity vars and let gitconfig decide.
# GIT_ASKPASS and GIT_SSH_COMMAND stay: those are how Coder brokers git auth.
set -e GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# No core dumps. kernel.core_pattern is the bare name `core`, so a crash writes
# the dump into the process's cwd: a SIGABRT in the Sentry MCP server left a
# 5.3G core.<pid> sitting in the repo it was started from.
ulimit -c 0

command -q rbenv; and status --is-interactive; and rbenv init - --no-rehash fish | source
test -f "$HOME/.cargo/env.fish"; and source "$HOME/.cargo/env.fish"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# Last, so nothing above (rbenv, cargo, OrbStack, the sourced env files) can put a Homebrew or curl-installed copy ahead of a declared tool: the Nix profiles move back to the front, in nix-darwin's order.
fish_add_path --path --move --prepend "$HOME/.nix-profile/bin" "/etc/profiles/per-user/$USER/bin" /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
