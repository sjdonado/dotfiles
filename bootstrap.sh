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
  mitmproxy ngrok \

$(brew --prefix)/opt/fzf/install

# Package managers
# Run after rustup-init, nvm install --lts
brew install npm n yarn rustup luarocks

# Window manager
brew tap koekeishiya/formulae
brew install yabai skhd

# Docker
brew install colima docker docker-compose lazydocker

# Awesome tools
brew install --cask \
  raycast spacelauncher ukelele \
  table-tool obsidian

brew install --cask --no-quarantine chromium

# Best font ever
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Zsh theme
# brew install romkatv/powerlevel10k/powerlevel10k

# Nvim processes from the shell
pip3 install neovim-remote

# Keyboard layouts setup
cp -Rp $PWD/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Symlinks
ln -sf "$PWD/shell/fish/config.fish" ~/.config/fish/config.fish
ln -s "$PWD/shell/zsh/.zshrc" ~/.zshrc

ln -s "$PWD/alacritty/alacritty.yml" ~/.config/alacritty.yml
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf
ln -s "$PWD/.ssh/config" ~/.ssh/config

bat --generate-config-file
ln -sf "$PWD/bat/config" "$(bat --config-file)"

ln -s "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/git/lazygit.yml" ~/Library/Application\ Support/lazygit/config.yml

ln -s "$PWD/nvim" ~/.config/nvim

ln -s "$PWD/yabai/.yabairc" ~/.yabairc
ln -s "$PWD/yabai/.skhdrc" ~/.skhdrc
