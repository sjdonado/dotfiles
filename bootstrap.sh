#!/bin/sh

##########################################
##            macos setup               ##
##########################################

# Setup fonts
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Setup alacritty
brew install alacritty
ln -sf "$PWD/alacritty/alacritty.toml" ~/.config/alacritty.toml

# Fix alacritty thin strokes on macos
defaults write org.alacritty AppleFontSmoothing -int 0

# Tmux config
brew install tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -sn "$PWD/tmux/.tmux.conf" ~/.tmux.conf

# Fish shell
brew install fish

echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish

mkdir -p ~/.config/fish/config.fish && \
ln -s "$PWD/fish/config.fish" ~/.config/fish/config.fish

# Nvim config
brew install nvim lua
ln -s "$PWD/nvim" ~/.config/nvim

# Essentials
brew install coreutils \
  tree bat fd gawk ripgrep \
  blueutil mackup \
  git-delta git-lfs

brew install --cask \
  firefox spotify \
  raycast ukelele notunes browserosaurus \
  monitorcontrol

# Tiling Window manager
brew install --cask amethyst # SIP unblocked not required

# Package managers
brew install fnm rustup luarocks pypenv crystal # run rustup-init
ln -sf "$PWD/fish/conf.d/fnm.fish" ~/.config/fish/conf.d/fnm.fish

# Docker
brew install colima docker docker-compose docker-buildx
colima start

# Nice to have
brew install --cask \
  table-tool db-browser-for-sqlite dbeaver-community \
  qbittorrent reverso utm bruno

brew install tor mitmproxy nmap redis \
  cloudflare/cloudflare/cloudflared \
  marp-cli mailpit

# Toolkit
brew tap shopify/shopify
brew install shopify-cli firebase-cli scc serverless

brew tap oven-sh/bun
brew install bun

brew tap amberframework/micrate
brew install micrate

# Keyboard layouts setup
cp -Rp $PWD/macos/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Dotfiles symlinks
ln -sf "$PWD/bat/config" ~/.config/bat/config
ln -sf "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/.ssh/config" ~/.ssh/config
ln -s "$PWD/.mackup.cfg" ~/.mackup.cfg
