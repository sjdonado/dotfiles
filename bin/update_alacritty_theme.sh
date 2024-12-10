#!/bin/bash

theme=$1

alacritty_config_path="$HOME/.config/dotfiles/alacritty/alacritty.toml"
alacritty_symlink_path="$HOME/.config/alacritty.toml"

sed -i "/^import = / s#^import = .*#import = [\"~/.config/alacritty/themes/${theme}.toml\"]#" "$alacritty_config_path"

# Recreate the symlink
ln -sf "$alacritty_config_path" "$alacritty_symlink_path"
