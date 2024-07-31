# Set locale
set -x LC_CTYPE en_US.UTF-8
set -x LC_ALL en_US.UTF-8

# Disable greeting
set -gx fish_greeting ''

# Replace prompt_hostname with ip address
function prompt_hostname
  echo ""
end

# Custom config
set -x HISTSIZE 20000

# Add binaries to PATH
# set -g -x PATH /usr/local/bin $PATH
set -g -x PATH /opt/homebrew/bin $PATH
set -g -x PATH $HOME/.local/bin $PATH

# Custom commands
alias workspace="sh ~/.config/dotfiles/bin/workspace.sh"

# cargo
set -Ua fish_user_paths $HOME/.cargo/bin

# pyenv
set -Ux PYENV_ROOT $HOME/.pyenv
set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
# pyenv init - | source

