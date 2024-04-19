# Set locale
set -x LC_CTYPE en_US.UTF-8
set -x LC_ALL en_US.UTF-8

# Disable greeting
set -gx fish_greeting ''

# Add binaries to PATH
# set -g -x PATH /usr/local/bin $PATH
# set -x PATH (python3 -m site --user-base)/bin $PATH
set -g -x PATH /opt/homebrew/bin $PATH

# Cargo env
set -Ua fish_user_paths $HOME/.cargo/bin

# Custom config
set -x HISTSIZE 20000