#!/bin/sh

# Setup alacritty
brew install alacritty

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Essentials
brew install \
  fish \
  tmux coreutils tmux-mem-cpu-load \
  tree bat fd gawk ripgrep fzf \
  git-delta lazygit \
  nvim lua tree-sitter shellcheck ccls \
  mackup \
  tor mitmproxy ngrok \

# Package managers
brew install fnm rustup luarocks

# Tiling Window manager
brew install --cask amethyst # SIP unblocked not required

# Docker
brew install colima docker docker-compose lazydocker

# Awesome tools
brew install --cask \
  firefox arc \
  raycast spacelauncher ukelele \
  table-tool discord obsidian \
  qbittorrent

# Best font ever
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Nvim processes from the shell
pip3 install neovim-remote

# Keyboard layouts setup
cp -Rp $PWD/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Dotfiles symlinks
ln -sf "$PWD/fish/config.fish" ~/.config/fish/config.fish
ln -sf "$PWD/fish/conf.d" ~/.config/fish

ln -sf "$PWD/bat/config" ~/.config/bat/config

ln -s "$PWD/alacritty/alacritty.yml" ~/.config/alacritty.yml
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf

ln -s "$PWD/nvim" ~/.config/nvim

ln -s "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/lazygit/config.yml" ~/Library/Application\ Support/lazygit/config.yml

ln -s "$PWD/.ssh/config" ~/.ssh/config

ln -s "$PWD/.mackup.cfg" ~/.mackup.cfg
