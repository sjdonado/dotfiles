# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Custom keymaps
alias vim=nvim
alias python=/usr/bin/python3
alias pip=pip3

# Custom config
setopt HIST_IGNORE_ALL_DUPS
export HISTSIZE=20000

source "$HOME/.cargo/env"

# fnm config
eval "$(fnm env --use-on-cd)"

# fzf config
source "$HOME/.config/dotfiles/zsh/fzf.zsh"

# helpers
source "$HOME/.config/dotfiles/zsh/private_memtime.zsh"

# zsh plugins
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Created by `pipx` on 2024-04-17 13:56:16
export PATH="$PATH:/Users/sjdonado/.local/bin"
