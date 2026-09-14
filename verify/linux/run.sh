#!/usr/bin/env bash
# Provision a throwaway Ubuntu container from this working tree and assert the
# result. This is how a change to linux.sh is checked: not by reading it, and
# not on a real box where a half-applied run leaves residue.
#
#   verify/linux/run.sh                     # current arch
#   verify/linux/run.sh --platform linux/amd64   # the other one
#   verify/linux/run.sh --shell             # drop into the provisioned box
#
# The working tree is copied in, not mounted read-write, so the container starts
# from exactly what is committed *and* what is still uncommitted, and can write
# to it without touching the host.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
IMAGE="dotfiles-verify-linux"
# Empty-array expansion under `set -u` is an error on bash 3.2 (macOS), so this
# carries a placeholder element rather than an empty array.
PLATFORM=()
SHELL_ONLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM=(--platform "$2"); shift 2 ;;
    --shell) SHELL_ONLY=1; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

echo "==> building $IMAGE"
docker build ${PLATFORM[@]+"${PLATFORM[@]}"} -q -t "$IMAGE" "$HERE" >/dev/null

# One container for the whole run, so the second provisioning pass sees the
# state the first one left behind. That is the only way the idempotency check
# means anything.
# GitHub's unauthenticated API allows 60 requests an hour per IP, and mise's
# github backend spends two per tool. A container behind a shared NAT runs out,
# and the run fails with 403s that have nothing to do with the change under
# test. A committed mise.lock needs no API calls at all (there is a check
# asserting exactly that), so the token is passed only when the lock is
# missing: with no scopes to spend it is still the user's full CLI credential,
# and every process in the container would otherwise inherit it. It needs no
# scopes for what it is spent on here.
GH_TOKEN_ENV=()
if [ ! -f "$ROOT/mise.lock" ]; then
  if token="$(gh auth token 2>/dev/null)" && [ -n "$token" ]; then
    GH_TOKEN_ENV=(-e "GITHUB_TOKEN=$token")
    echo "==> no mise.lock; passing a GitHub token through (avoids API rate limits)"
  else
    echo "==> no mise.lock and no GitHub token found; tools from GitHub releases may hit the 60/hour limit"
  fi
else
  echo "==> mise.lock present; installs need no GitHub API calls, so no token is passed"
fi

CID="$(docker run ${PLATFORM[@]+"${PLATFORM[@]}"} ${GH_TOKEN_ENV[@]+"${GH_TOKEN_ENV[@]}"} -d "$IMAGE" sleep infinity)"
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true' EXIT INT TERM

run() { docker exec -u dev -w /home/dev "$CID" bash -lc "$1"; }

echo "==> copying the working tree in (secrets stay on the host)"
# Staged from the host through a pipe, never mounted: a bind mount would leave
# the live tree, gitignored secrets included (.env, .ssh/private.conf), readable
# inside the container for the whole run, next to third-party install scripts.
# tar, not cp -a: the checkout may sit on a volume with .Trashes/.fseventsd
# entries the container user cannot read, and one unreadable entry fails the
# whole copy. .git is a worktree pointer file here; excluding it keeps the
# guest free of host git state either way. Exclusion lists mirror
# verify/macos/run.sh; keep both in sync when a new secret-bearing name appears.
run 'mkdir -p ~/.config/dotfiles'
tar -C "$ROOT" --exclude=.git --exclude=.agent --exclude=.fseventsd --exclude=.Trashes --exclude=.env --exclude=.env.* --exclude=.ssh/private.conf -cf - . | docker exec -i -u dev -w /home/dev "$CID" tar -C ~/.config/dotfiles -xf -

if [ "$SHELL_ONLY" = 1 ]; then
  echo "==> provisioning, then handing you a shell"
  run '~/.config/dotfiles/linux.sh --install' || true
  docker exec -it -u dev -w /home/dev "$CID" bash -l
  exit 0
fi

echo "==> first run: linux.sh --install"
time run '~/.config/dotfiles/linux.sh --install'

echo "==> verifying"
run '~/.config/dotfiles/verify/linux/verify.sh'

echo "==> second run: linux.sh --install again (idempotency)"
run '~/.config/dotfiles/linux.sh --install' >/tmp/second-run.log 2>&1 \
  || { echo "second run failed:"; tail -30 /tmp/second-run.log; exit 1; }

echo "==> verifying again"
run '~/.config/dotfiles/verify/linux/verify.sh'

# A second pass must not keep appending to the shell rc files. Every block
# linux.sh writes is guarded by a grep, and this is what proves the guards hold.
echo "==> checking the rc files were not doubled"
run 'for rc in ~/.bashrc ~/.zshrc ~/.profile ~/.zshenv; do
  for marker in "dotfiles: tools on PATH" "dotfiles: git identity from gitconfig" "dotfiles: exec fish"; do
    n=$(grep -cF "$marker" "$rc" || true)
    if [ "$n" -gt 1 ]; then echo "FAIL $rc has $n copies of: $marker"; exit 1; fi
  done
done; echo "  ok   no duplicated rc blocks"'

echo
echo "==> all checks passed"
