# Set locale
set -x LC_CTYPE en_US.UTF-8
set -x LC_ALL en_US.UTF-8

# Disable greeting
set -gx fish_greeting ''

# Add binaries to PATH
set -g -x PATH /usr/local/bin $PATH
set -g -x PATH (brew --prefix)/bin $PATH
set -x PATH (python3 -m site --user-base)/bin $PATH

# Cargo env
set -Ua fish_user_paths $HOME/.cargo/bin

# Custom alias
alias vim nvim
alias python python3
alias pip pip3

# Custom config
set -x HISTSIZE 20000

# FZF config
set -x FZF_PREVIEW_COMMAND "bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"

set -x FZF_CTRL_T_OPTS "\
  --min-height 30 \
  --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"

set -x FZF_CTRL_R_OPTS "\
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' \
  --color header:italic \
  --header 'Press CTRL-Y to copy command into clipboard'"

# Load fzf
if test -f ~/.fzf.fish
  source ~/.fzf.fish
end
