#!/bin/bash

brew install tmux tree tzf nvm lua tree-sitter ripgrep fd
$(brew --prefix)/opt/fzf/install

brew tap homebrew/cask-fonts
brew install --cask font-hack-nerd-font

# lspconfig tsserver
npm i -g typescript typescript-language-server

# lspconfig eslint
npm i -g vscode-langservers-extracted

# git setup
git config --global user.name 'Juan Rodriguez'
git config --global user.email sjdonado@uninorte.edu.co
git config --global core.editor vim
git config --global --add --bool push.autoSetupRemote true

ln -s $PWD/.tmux.conf ~/.tmux.conf
