# Interactive zsh. On macOS this file is linked to ~/.zshrc. On Linux the managed ~/.zshrc sources it.

# Locale
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export EDITOR=nvim
if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export COREPACK_HOME="$HOME/.cache/corepack"
fi

# bat resolves light/dark itself: BAT_THEME=auto asks the terminal, and these two name which theme to use on each side.
export BAT_THEME=auto
export BAT_THEME_DARK=GitHub-Dark
export BAT_THEME_LIGHT=GitHub-Light

# Custom man pages, ahead of the default search path (the trailing colon keeps it).
export MANPATH="$HOME/.config/dotfiles/man:${MANPATH}"

# Direct package and vendor paths. typeset -U drops duplicates, keeping the first.
typeset -U path
if [[ "$OSTYPE" == darwin* ]]; then
  path=(/opt/homebrew/bin /opt/homebrew/sbin "$HOME/.local/bin" "$HOME/.opencode/bin" "$PNPM_HOME" "$HOME/go/bin" "$HOME/.cargo/bin" "$HOME/Library/Android/sdk/platform-tools" $path)
else
  path=("$HOME/.local/bin" "$HOME/.opencode/bin" "$PNPM_HOME" "$HOME/go/bin" "$HOME/.cargo/bin" $path)
fi

# -u accepts completion directories the primary account owns, which avoids a prompt in other accounts.
autoload -Uz compinit && compinit -u
autoload -Uz bashcompinit && bashcompinit

# Prompt: epoch seconds, the directory (green on macOS, blue on Linux), the exit status in red when it is not 0.
[[ $OSTYPE == darwin* ]] && _prompt_color=green || _prompt_color=blue
PROMPT="%D{%s} %F{$_prompt_color}%~%f%(?..%F{red}[%?]%f)> "
unset _prompt_color

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
setopt SHARE_HISTORY HIST_IGNORE_SPACE HIST_IGNORE_DUPS

# Aliases
[[ "$OSTYPE" == darwin* ]] && alias python=/usr/bin/python3
alias wtc="wt switch --create --no-cd"
alias wtr="wt remove -D --force"
alias wtl="wt list --full"
# Create a worktree and hand the terminal straight to an agent. -x replaces the wt process after pre-start provisioning, so the agent gets a full TTY.
#   wty my-branch -- 'use yolo to fix the thing'
alias wty="wt switch --create -x claude --"
alias wtp="wt step prune --min-age 7d --dry-run"

# ctrl+f: fuzzy-find a git repository and cd into it.
fzf-git-repos() {
  local base="$HOME/Developer"
  [[ -d "$base" ]] || base="$HOME"
  local repo
  repo=$(fd -H -t d -t f --prune --max-depth 6 '^\.git$' "$base" 2>/dev/null | sed 's|/\.git/*$||' | fzf --height 40% --reverse --prompt "git repo> ")
  [[ -n "$repo" ]] && cd "$repo"
  zle reset-prompt
}
zle -N fzf-git-repos
bindkey '^F' fzf-git-repos

# Variables this repository keeps out of git.
if [[ -f "$HOME/.config/dotfiles/.env" ]]; then
  set -a
  . "$HOME/.config/dotfiles/.env"
  set +a
fi

# Coder writes the workspace session env (API tokens, GIT_ASKPASS, ...) for shells its agent did not spawn. It is POSIX sh, so it is read with sh semantics and quietly.
[[ -f "$HOME/.config/coder/env.sh" ]] && emulate sh -c '. "$HOME/.config/coder/env.sh"' >/dev/null 2>&1

# Coder also injects a git identity, and env beats ~/.gitconfig, so the tracked user.name/user.email would be ignored. GIT_ASKPASS and GIT_SSH_COMMAND stay: those are how Coder brokers git auth.
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

# No core dumps: a crash would otherwise write one into the process's working directory, usually a repository.
ulimit -c 0

# OrbStack: command-line tools and integration.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

(( $+commands[rbenv] )) && eval "$(rbenv init - --no-rehash zsh)"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
