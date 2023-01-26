#!/bin/bash

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Packer
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# Download dependencies
brew install tmux nvim tree fzf nvm lua tree-sitter ripgrep fd gawk coreutils tmux-mem-cpu-load
$(brew --prefix)/opt/fzf/install

# iTerm2 font
brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# lsp most used setup
npm i -g vscode-langservers-extracted yaml-language-server

# typescript setup
npm i -g typescript typescript-language-server
npm i -g vscode-langservers-extracted

# go setup
brew install staticcheck
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest

# npm utils
npm i -g nosync-icloud

ln -s $PWD/.gitconfig ~/.gitconfig
ln -s $PWD/.tmux.conf ~/.tmux.conf
