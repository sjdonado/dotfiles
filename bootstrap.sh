#!/bin/sh

# Setup alacritty
brew install alacritty

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Essentials
brew install \
  fish \
  tmux coreutils \
  tree bat fd gawk ripgrep fzf \
  blueutil mackup \
  git-delta git-lfs \
  nvim lua tree-sitter shellcheck ccls \
  tor mitmproxy nmap \
  marp-cli redis

# Docker
brew install colima docker docker-compose docker-buildx
colima start --vm-type vz

# Package managers
brew install fnm rustup luarocks yarn

# Tiling Window manager
brew install --cask amethyst # SIP unblocked not required

# Casks
brew install --cask \
  firefox \
  raycast ukelele \
  qbittorrent table-tool db-browser-for-sqlite \
  reverso utm

brew install --cask --no-quarantine chromium

# Toolkit
brew tap shopify/shopify
brew install shopify-cli

brew tap oven-sh/bun
brew install bun

# Best font ever
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Nvim processes from the shell
pip3 install neovim-remote

# Keyboard layouts setup
cp -Rp $PWD/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Spotify player
cargo install spotify_player --features lyric-finder,image,media-control
~/.config/dotfiles/spotify-player/setup.sh

# Dotfiles symlinks
ln -sf "$PWD/fish/config.fish" ~/.config/fish/config.fish
ln -sf "$PWD/fish/conf.d" ~/.config/fish

ln -sf "$PWD/bat/config" ~/.config/bat/config

ln -s "$PWD/alacritty/alacritty.yml" ~/.config/alacritty.yml
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf

ln -s "$PWD/nvim" ~/.config/nvim

ln -s "$PWD/git/.gitconfig" ~/.gitconfig

ln -s "$PWD/.ssh/config" ~/.ssh/config

ln -s "$PWD/.mackup.cfg" ~/.mackup.cfg

ln -s "$PWD/spotify-player/keymap.toml" ~/.config/spotify-player/keymap.toml
