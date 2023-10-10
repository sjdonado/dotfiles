#!/bin/sh

source "$HOME/.config/dotfiles/.env"

cp -rf "$PWD/spotify-player/app.toml" "$HOME/.config/spotify-player/app.toml"
perl -pe 's/client_id = ""/client_id = "'"$SPOTIFY_CLIENT_ID"'"/' -i "$HOME/.config/spotify-player/app.toml"

echo "spotify_player setup done"
