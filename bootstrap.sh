#!/bin/sh

##########################################
##            macos setup               ##
##########################################

# Install dependencies from Brewfile
brew bundle install

# Setup terminal
mkdir -p "$HOME/.config/ghostty" "$HOME/.config/ghostty/themes"
ln -sf "$PWD/ghostty/config" "$HOME/.config/ghostty/config"
ln -sf "$PWD/ghostty/themes/"* "$HOME/.config/ghostty/themes/"

# Tmux config
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -sn "$PWD/tmux/.tmux.conf" ~/.tmux.conf

# Shell setup (fish)
chsh -s "$(brew --prefix)/bin/fish"
mkdir -p "$HOME/.config/fish" "$HOME/.config/fish/functions"
ln -sf "$PWD/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -sf "$PWD/fish/functions/"* "$HOME/.config/fish/functions/"

# Package managers
rustup-init
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Docker
# colima start
ln -sf "$PWD/docker/colima.yaml" ~/.colima/default/colima.yaml
ln -sf "$PWD/docker/config.json" ~/.docker/config.json

# Keyboard layouts setup
cp -Rp "$PWD/macos/ukelele/"* "$HOME/Library/Keyboard Layouts/"

# Dotfiles symlinks
ln -s "$PWD/.ssh/config" "$HOME/.ssh/config"
ln -s "$PWD/.mackup.cfg" "$HOME/.mackup.cfg"
ln -sf "$PWD/git/.gitconfig" "$HOME/.gitconfig"

ln -sf "$PWD/bat/config" "$HOME/.config/bat/config"
ln -sf "$PWD/pgcli/config" "$HOME/.config/pgcli/config"

# Nvim config
ln -s "$PWD/nvim" "$HOME/.config/nvim"
