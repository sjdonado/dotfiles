# A throwaway Ubuntu that looks like a fresh remote box: no tooling, one
# non-root sudo user, no dotfiles. linux.sh has to bring everything else.
#
# Deliberately minimal. Anything installed here is something linux.sh is no
# longer proven to install, so only what an image cannot boot without goes in:
# curl to fetch nothing more than the script itself, sudo because linux.sh
# expects to apt-get as a normal user, and ca-certificates for TLS.
FROM ubuntu:24.04

RUN apt-get update -qq \
  && apt-get install -y -qq --no-install-recommends curl ca-certificates sudo \
  && rm -rf /var/lib/apt/lists/*

ARG USER=dev
RUN useradd -m -s /bin/bash "$USER" \
  && echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USER"

USER dev
WORKDIR /home/dev
ENV HOME=/home/dev
