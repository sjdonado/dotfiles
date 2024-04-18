#!/bin/sh

#
# Essentials
#
sudo apt-get update \
  sudo apt-get -y install \
  build-essential unzip bindfs xdg-utils \
  tree bat gawk ripgrep \
  fish tmux neovim

#
# Fish setup
#
# echo /usr/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s "$PWD/tmux/.tmux.conf" ~/.tmux.conf


#
# Docker setup
#
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the latest version
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo groupadd docker
sudo usermod -aG docker $USER

# Install docker-compose standalone
sudo curl -SL https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-linux-aarch64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

#
# Node.js setup
#
curl -fsSL https://fnm.vercel.app/install | bash
curl -fsSL https://bun.sh/install | bash
