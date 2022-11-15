#!/bin/bash

brew install tmux tree tzf lua tree-sitter ripgrep fd 
$(brew --prefix)/opt/fzf/install

brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# lspconfig tsserver
npm install -g typescript typescript-language-server

# lspconfig eslint
npm i -g vscode-langservers-extracted
