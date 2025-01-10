#!/bin/bash

theme=$1

alacritty_config_path="$HOME/.config/dotfiles/alacritty/alacritty.toml"
theme_file="$HOME/.config/alacritty/themes/${theme}.toml"
alacritty_symlink_path="$HOME/.config/alacritty.toml"

if [[ ! -f "$theme_file" ]]; then
  echo "Error: Theme file '$theme_file' does not exist."
  exit 1
fi

sed -i '' "s|^import = .*|import = [\"$theme_file\"]|" "$alacritty_config_path"

ln -sf "$alacritty_config_path" "$alacritty_symlink_path"

echo "Alacritty theme updated to '$theme'. Symlink refreshed."
