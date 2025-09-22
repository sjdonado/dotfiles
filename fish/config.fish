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
    string join '' -- (set_color green) (prompt_pwd) (set_color normal) $stat '> '
end

function fish_right_prompt
    date +%s
end

# General settings
set -g fish_history fish
set -g fish_history_max 20000

# Path configurations
set -x PNPM_HOME "$HOME/Library/pnpm"
set -x PATH $HOME/.cargo/bin $PATH

fish_add_path "$HOME/.local/bin"
fish_add_path /opt/homebrew/bin

fish_add_path "$HOME/.bun/bin"
fish_add_path "$PNPM_HOME"
fish_add_path "$HOME/go/bin"

bind ctrl-f "tmux-sessionizer"

# Aliases
alias python=/usr/bin/python3
alias workspace=~/.config/dotfiles/bin/workspace

# Source external variables
. "$HOME/.config/dotfiles/.env"

status --is-interactive; and rbenv init - --no-rehash fish | source
source "$HOME/.cargo/env.fish"
