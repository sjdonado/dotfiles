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

# Setup alacritty themes
mkdir -p ~/.config/alacritty/themes
ln -sf $PWD/alacritty/themes/light.toml ~/.config/alacritty/themes/light.toml
ln -sf $PWD/alacritty/themes/dark.toml ~/.config/alacritty/themes/dark.toml

# Tmux config
brew install tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -sn "$PWD/tmux/.tmux.conf" ~/.tmux.conf

# Shell setup
chsh -s /bin/zsh
brew install starship fzf

ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
ln -sf "$PWD/zsh/starship.toml" ~/.config/starship.toml

# Nvim config
brew install nvim lua
ln -s "$PWD/nvim" ~/.config/nvim

# Essentials
brew install coreutils \
  tree bat fd gawk ripgrep \
  blueutil mackup \
  git-delta git-lfs

brew install --cask \
  firefox spotify libreoffice \
  raycast ukelele notunes browserosaurus \
  monitorcontrol

# Tiling Window manager
# brew install --cask amethyst # SIP unblocked not required

# Package managers
brew install fnm rustup luarocks pypenv crystal
rustup-init

# Docker
brew install colima docker docker-compose docker-buildx
colima start

# Nice to have
brew install --cask \
  tableplus \
  qbittorrent reverso

# Tailscale setup
brew install tailscale mosh
sudo tailscaled install-system-daemon
tailscale up

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
