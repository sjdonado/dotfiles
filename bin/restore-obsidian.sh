#!/bin/sh

if [ ! -d "$HOME/Library/Mobile Documents/iCloud~md~obsidian" ]; then
 cp -R "$PWD/.obsidian" "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/$(id -un)"
fi
