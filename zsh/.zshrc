export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

alias python=/usr/bin/python3
alias workspace=~/.config/dotfiles/bin/workspace.sh
alias brew="sudo -Hu sjdonado brew"

export HISTSIZE=20000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="sjdonado"

zstyle ':omz:alpha:lib:git' async-prompt yes
plugins=()

source $ZSH/oh-my-zsh.sh

# Package managers
source "$HOME/.cargo/env"
export PATH="/Users/sjdonado/.bun/bin:$PATH"

export PNPM_HOME="/Users/juan/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"

export FZF_CTRL_T_OPTS="
  --min-height 30
  --color bw
  --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"

export FZF_CTRL_R_OPTS="
  --height 10%
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color bw
  --header 'Press CTRL-Y to copy into clipboard'"

source <(fzf --zsh)
