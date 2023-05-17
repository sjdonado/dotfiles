#!/bin/sh

# sudo bash -c "echo '$(id -un) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai)) $(which yabai) --load-sa' >> /private/etc/sudoers.d/yabai"
chmod +x ~/.yabairc

yabai --start-service
skhd --start-service
