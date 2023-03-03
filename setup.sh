#!/bin/bash

# Install iTerm2
brew install --cask iterm2-beta

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Dependencies
brew install tmux nvim tree fzf lua nvm tree-sitter ripgrep fd gawk coreutils tmux-mem-cpu-load shellcheck ccls emscripten
$(brew --prefix)/opt/fzf/install

# Package managers
# run after rustup-init, nvm install --lts
brew install npm yarn rustup luarocks

# Awesome tools
brew install mitmproxy ngrok colima docker docker-compose && brew install --cask insomnia raycast

# iTerm2 font
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# Link config files
ln -s "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf

ln -s "$PWD/nvim" ~/.config/nvim
ln -s "$PWD/.ssh/config" ~/.ssh/config
