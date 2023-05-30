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
# Run after rustup-init
brew install fnm rustup luarocks

# Tiling Window manager
# brew tap koekeishiya/formulae
# brew install yabai skhd
brew install --cask amethyst # SIP unblocked not required

# Docker
brew install colima docker docker-compose lazydocker

# Awesome tools
brew install --cask \
  firefox google-chrome \
  raycast spacelauncher ukelele \
  table-tool discord obsidian \
  qbittorrent

# Best font ever
brew tap homebrew/cask-fonts
brew install font-hack-nerd-font

# Zsh theme
# brew install romkatv/powerlevel10k/powerlevel10k
# $(brew --prefix)/opt/fzf/install

# Nvim processes from the shell
pip3 install neovim-remote

# Keyboard layouts setup
cp -Rp $PWD/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Dotfiles
ln -sf "$PWD/shell/fish/config.fish" ~/.config/fish/config.fish
ln -sf "$PWD/shell/fish/conf.d/fnm.fish" ~/.config/fish/conf.d/fnm.fish
# ln -s "$PWD/shell/zsh/.zshrc" ~/.zshrc

ln -s "$PWD/alacritty/alacritty.yml" ~/.config/alacritty.yml
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf
ln -s "$PWD/.ssh/config" ~/.ssh/config

bat --generate-config-file
ln -sf "$PWD/bat/config" "$(bat --config-file)"

ln -s "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/git/lazygit.yml" ~/Library/Application\ Support/lazygit/config.yml

ln -s "$PWD/nvim" ~/.config/nvim

# ln -s "$PWD/yabai/.yabairc" ~/.yabairc
# ln -s "$PWD/yabai/.skhdrc" ~/.skhdrc
