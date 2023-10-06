#!/bin/sh

source "$HOME/.config/dotfiles/.env"
perl -pe 's/client_id = ""/client_id = "'"$SPOTIFY_CLIENT_ID"'"/' -i "$HOME/.config/dotfiles/spotify-player/app.toml"
spotify_player
perl -pe 's/client_id = "[^"]*"/client_id = ""/' -i "$HOME/.config/dotfiles/spotify-player/app.toml"
