# Set locale
set -x LC_CTYPE en_US.UTF-8
set -x LC_ALL en_US.UTF-8

# Disable greeting
set -gx fish_greeting ''

# Add binaries to PATH
set -g -x PATH /usr/local/bin $PATH
set -x PATH (python3 -m site --user-base)/bin $PATH

# Cargo env
set -Ua fish_user_paths $HOME/.cargo/bin

# Custom alias
alias vim nvim
alias python python3
alias pip pip3
alias spotify="bash ~/.config/dotfiles/spotify-player/run.sh"

# Custom config
set -x HISTSIZE 20000
