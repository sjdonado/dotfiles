#!/bin/bash

brew install tmux tree tzf nvm lua tree-sitter ripgrep fd gawk coreutils tmux-mem-cpu-load
$(brew --prefix)/opt/fzf/install

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
