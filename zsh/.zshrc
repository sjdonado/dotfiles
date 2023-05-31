export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme

export PATH="$(yarn global bin 2> >(grep -v warning 1>&2)):$PATH"

# Custom keymaps
alias vim=nvim
alias python=/usr/bin/python3

# Custom config
export HISTSIZE=20000

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# export NVM_DIR="$HOME/.nvm"
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

source "$HOME/.cargo/env"

# fzf config
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"

export FZF_CTRL_T_OPTS="
  --min-height 30
  --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"

export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
