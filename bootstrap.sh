#!/bin/sh

##########################################
##            macos setup               ##
##########################################

# Install dependencies from Brewfile
brew bundle install

# Setup alacritty
ln -sf "$PWD/alacritty/alacritty.toml" ~/.config/alacritty.toml

# # Fix alacritty thin strokes on macos
defaults write org.alacritty AppleFontSmoothing -int 0

# # Setup alacritty themes
mkdir -p ~/.config/alacritty/themes
ln -sf $PWD/alacritty/themes/light.toml ~/.config/alacritty/themes/light.toml
ln -sf $PWD/alacritty/themes/dark.toml ~/.config/alacritty/themes/dark.toml

# Setup kitty (optional)
# ln -sf $PWD/kitty/kitty.conf ~/.config/kitty/kitty.conf
# ln -sf $PWD/kitty/light-theme.conf ~/.config/kitty/light-theme.conf
# ln -sf $PWD/kitty/dark-theme.conf ~/.config/kitty/dark-theme.conf

# Tmux config
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -sn "$PWD/tmux/.tmux.conf" ~/.tmux.conf

# Shell theme setup
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
ln -sf "$PWD/zsh/sjdonado.zsh-theme" ~/.oh-my-zsh/themes/sjdonado.zsh-theme

# Package managers
rustup-init

# Docker
colima start
echo '"cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]' >> ~/.docker/config.json

# Keyboard layouts setup
cp -Rp $PWD/macos/ukelele/* "$HOME/Library/Keyboard Layouts/"

# Dotfiles symlinks
ln -sf "$PWD/bat/config" ~/.config/bat/config
ln -sf "$PWD/git/.gitconfig" ~/.gitconfig
ln -s "$PWD/.ssh/config" ~/.ssh/config
ln -s "$PWD/.mackup.cfg" ~/.mackup.cfg

# Nvim config
ln -s "$PWD/nvim" ~/.config/nvim
