#!/bin/sh

echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells

# Make fish your default shell
chsh -s /opt/homebrew/bin/fish
