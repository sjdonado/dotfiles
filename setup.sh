#!/bin/bash

brew install tmux git-delta tree tzf lua tree-sitter ripgrep fd
$(brew --prefix)/opt/fzf/install

brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# lspconfig tsserver
npm install -g typescript typescript-language-server

# lspconfig eslint
npm i -g vscode-langservers-extracted

# git-delta setup
git config --global core.pager "delta --light"
git config --global delta.side-by-side true

ln -s .tmux.conf ~/.tmux.conf
