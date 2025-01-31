#!/bin/sh

##########################################
##  Install Node.js LTS for Neovim LSP  ##
##########################################
NODE_DIR="$HOME/.local/share/nvim/node"
NODE_VERSION=$(curl -fsSL "https://nodejs.org/dist/index.json" | jq -r '[.[] | select(.lts != false)] | first | .version' | sed 's/v//')

if [ -z "$NODE_VERSION" ]; then
  echo "Failed to fetch the latest Node.js LTS version."
  exit 1
fi

NODE_TAR="node-v${NODE_VERSION}-darwin-arm64.tar.gz"
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TAR}"

mkdir -p "$NODE_DIR"
if [ ! -d "$NODE_DIR/bin" ]; then
  echo "Installing Node.js LTS ($NODE_VERSION) for Neovim on Apple Silicon..."
  curl -fsSL "$NODE_URL" | tar -xz -C "$NODE_DIR" --strip-components=1
else
  echo "Node.js LTS already installed in $NODE_DIR"
fi
