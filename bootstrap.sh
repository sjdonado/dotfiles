#!/bin/sh

# setup alacritty
brew install alacritty

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim

# essentials
brew install \
  tmux coreutils tmux-mem-cpu-load \
  tree bat fd gawk ripgrep fzf \
  git-delta lazygit \
  nvim lua nvm tree-sitter shellcheck ccls \
  mitmproxy ngrok \

$(brew --prefix)/opt/fzf/install

# package managers
# run after rustup-init, nvm install --lts
brew install npm yarn rustup luarocks

# window manager
brew tap koekeishiya/formulae
brew install yabai skhd

# docker
brew install colima docker docker-compose lazydocker

# awesome tools
brew install --cask \
  raycast spacelauncher ukelele \
  table-tool obsidian

brew install --cask --no-quarantine chromium

# best font ever
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# zsh theme
brew install romkatv/powerlevel10k/powerlevel10k

# nvim processes from the shell
pip3 install neovim-remote

# keyboard layouts setup
cp -Rp $PWD/ukelele/* "$HOME/Library/Keyboard Layouts/"

# symlinks
ln -s "$PWD/alacritty/alacritty.yml" ~/.config/alacritty.yml

ln -s "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf
ln -s "$PWD/zsh/.zshrc" ~/.zshrc

ln -s "$PWD/nvim" ~/.config/nvim
ln -s "$PWD/.ssh/config" ~/.ssh/config

ln -s "$PWD/git/lazygit.yml" ~/Library/Application\ Support/lazygit/config.yml

ln -s "$PWD/yabai/.yabairc" ~/.yabairc
ln -s "$PWD/yabai/.skhdrc" ~/.skhdrc
