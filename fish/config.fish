# Locale
set -x LC_CTYPE en_US.UTF-8
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8

# Theme settings
set -g fish_greeting ""
function prompt_hostname
    if test (uname) = "Darwin"
        # Try en0 (typically Wi-Fi) first, then en1 (often Ethernet)
        set ip_address (ipconfig getifaddr en0 2>/dev/null)
        if test -z "$ip_address"
            set ip_address (ipconfig getifaddr en1 2>/dev/null)
        end
    else
        set ip_address (hostname -I 2>/dev/null | awk '{print $1}')
        # Fallback if hostname -I is not available
        if test -z "$ip_address"
            set ip_address (ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n1)
        end
    end

    if test -n "$ip_address"
        echo "$ip_address"
    end
end

# General settings
set -g fish_history fish
set -g fish_history_max 20000

# Path configurations
set -x PNPM_HOME "$HOME/Library/pnpm"
set -x PATH $HOME/.cargo/bin $PATH
set PATH $PATH /Users/juan/.local/bin

fish_add_path /opt/homebrew/bin
fish_add_path "$HOME/.bun/bin"
fish_add_path "$PNPM_HOME"

# Aliases
alias python=/usr/bin/python3
alias workspace=~/.config/dotfiles/bin/workspace.sh
alias brew="sudo -Hu sjdonado brew"

. "$HOME/.config/dotfiles/.env"
