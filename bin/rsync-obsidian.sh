#! /bin/sh

source_dir="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/$(id -un)/.obsidian"
dest_dir="$PWD/.obsidian"

rsync -a --update --delete "$source_dir/" "$dest_dir/"
