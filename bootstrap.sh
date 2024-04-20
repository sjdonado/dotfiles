#!/bin/sh

##########################################
##            macos setup               ##
##########################################

# Setup alacritty
brew install alacritty

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Essentials
brew install \
  fish tmux coreutils \
  tree bat fd gawk ripgrep \
  blueutil mackup \
  git-delta git-lfs \
  nvim lua \
  tor mitmproxy nmap redis \
  cloudflare/cloudflare/cloudflared \
  marp-cli mailpit bruno \

# Fish shell
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
ln -sf "$PWD/fish/config.fish" ~/.config/fish/config.fish

# Nvim config
ln -s "$PWD/nvim" ~/.config/nvim

# Docker
brew install colima docker docker-compose docker-buildx
colima start

# Package managers
brew install fnm rustup luarocks pypenv
ln -sf "$PWD/fish/conf.d/fnm.fish" ~/.config/fish/conf.d/fnm.fish

# Tiling Window manager
brew install --cask amethyst # SIP unblocked not required

# Casks
brew install --cask \
  firefox \
  raycast ukelele \
  table-tool db-browser-for-sqlite dbeaver-community \
  qbittorrent reverso utm browserosaurus \
  notunes

brew install --cask --no-quarantine chromium

# Toolkit
brew tap shopify/shopify
brew install shopify-cli firebase-cli scc serverless

brew tap oven-sh/bun
brew install bun

# Best font ever
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Keyboard layouts setup
cp -Rp $PWD/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Dotfiles symlinks
ln -sf "$PWD/bat/config" ~/.config/bat/config

ln -s "$PWD/alacritty/alacritty.toml" ~/.config/alacritty.toml
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf

ln -s "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/.ssh/config" ~/.ssh/config

ln -s "$PWD/.mackup.cfg" ~/.mackup.cfg
