#!/bin/bash
#
# Install iTerm2
brew install --cask iterm2-beta

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Dependencies
brew install tmux nvim tree fzf lua nvm tree-sitter ripgrep fd gawk coreutils tmux-mem-cpu-load
$(brew --prefix)/opt/fzf/install

# Package managers
# run after rustup-init, nvm install --lts
brew install npm yarn rustup luarocks

# Awesome tools
brew install mitmproxy ngrok && brew install --cask insomnia raycast

# iTerm2 font
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

ln -s $PWD/config/.gitconfig ~/.gitconfig
ln -s $PWD/config/.tmux.conf ~/.tmux.conf
