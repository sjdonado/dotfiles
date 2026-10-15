#!/usr/bin/env bash
# Provision a throwaway Ubuntu container from this working tree with linux.sh, twice, and assert the result. This is how a change to the Linux declaration is checked: not by reading it, and not on a real box where a half-applied run leaves residue.
#
#   verify/linux/run.sh                          # current arch
#   verify/linux/run.sh --platform linux/amd64   # the other one
#   verify/linux/run.sh --shell                  # drop into the provisioned box
#
# The working tree is copied in, not mounted, so the container sees exactly what is committed and what is still uncommitted, and can write to it without touching the host. Needs Docker only: Nix is installed inside the container by linux.sh itself.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
IMAGE="dotfiles-verify-linux"
# Empty-array expansion under `set -u` is an error on bash 3.2 (macOS), hence the ${X[@]+...} form below.
PLATFORM=()
SHELL_ONLY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --platform) PLATFORM=(--platform "$2"); shift 2 ;;
    --shell) SHELL_ONLY=1; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# One image per platform, so an amd64 build does not replace the native one under the same tag.
[ "${#PLATFORM[@]}" -eq 0 ] || IMAGE="$IMAGE-${PLATFORM[1]//\//-}"
echo "==> building $IMAGE"
docker build ${PLATFORM[@]+"${PLATFORM[@]}"} -q -t "$IMAGE" "$HERE" >/dev/null

# An emulated architecture (amd64 on Apple silicon) cannot load Nix's seccomp syscall filter, so linux.sh passes this line to the installer there. Real boxes of that architecture do not need it.
EMULATED=()
if [ "$(docker run --rm ${PLATFORM[@]+"${PLATFORM[@]}"} "$IMAGE" uname -m)" != "$(uname -m | sed 's/arm64/aarch64/')" ]; then
  EMULATED=(-e "NIX_INSTALLER_EXTRA_CONF=filter-syscalls = false")
fi

# One container for the whole run, so the second pass sees the state the first one left behind. That is the only way the idempotency check means anything.
LOGS="$(mktemp -d)"
CID="$(docker run ${PLATFORM[@]+"${PLATFORM[@]}"} ${EMULATED[@]+"${EMULATED[@]}"} -d "$IMAGE" sleep infinity)"
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true; rm -rf "$LOGS"' EXIT INT TERM

run() { docker exec -u dev -w /home/dev "$CID" bash -lc "$1"; }

echo "==> copying the working tree in (secrets stay on the host)"
# Through a pipe, never a bind mount: a mount would leave gitignored secrets (.env, .ssh/private.conf) readable in the container for the whole run. verify/tree.sh lists what the git flake sees, so ignored files stay on the host. Without .git the flake is read as a plain directory, so uncommitted and unstaged files count.
run 'mkdir -p ~/.config/dotfiles'
"$ROOT/verify/tree.sh" | COPYFILE_DISABLE=1 tar --no-xattrs --no-fflags -C "$ROOT" -T - -cf - | docker exec -i -u dev -w /home/dev "$CID" tar -C /home/dev/.config/dotfiles -xf -

if [ "$SHELL_ONLY" = 1 ]; then
  echo "==> provisioning, then handing you a shell"
  run '~/.config/dotfiles/linux.sh' || true
  docker exec -it -u dev -w /home/dev "$CID" bash -l
  exit 0
fi

echo "==> first run: linux.sh"
SECONDS=0
run '~/.config/dotfiles/linux.sh' > "$LOGS/run1.log" 2>&1 || { echo "first run failed:"; tail -40 "$LOGS/run1.log"; exit 1; }
grep -E '^==>|dotfiles:' "$LOGS/run1.log" | sed 's/^/  /'
echo "  first run took ${SECONDS}s"

echo "==> verifying"
run '~/.config/dotfiles/verify/linux/verify.sh'

# A step that skips has to say so: no herdr server runs in the container, so the plugin step must report itself skipped rather than pass silently.
if grep -q 'dotfiles: skipped herdr-plugins: no herdr server is running' "$LOGS/run1.log"; then
  echo "  ok   the herdr plugin step reported itself skipped"
else
  echo "  FAIL the herdr plugin step did not report its skip"; exit 1
fi

before="$(run 'readlink ~/.local/state/nix/profiles/home-manager; find ~ -name "*.pre-nix" -o -name "*.backup*" | sort')"
# An empty first line would make the comparison below pass without comparing a generation.
[ -n "$(head -1 <<<"$before")" ] || { echo "  FAIL no home-manager generation after the first run"; exit 1; }

echo "==> second run: linux.sh again (idempotency)"
run '~/.config/dotfiles/linux.sh' > "$LOGS/run2.log" 2>&1 || { echo "second run failed:"; tail -40 "$LOGS/run2.log"; exit 1; }

echo "==> verifying again"
run '~/.config/dotfiles/verify/linux/verify.sh'

echo "==> checking the second run changed nothing"
after="$(run 'readlink ~/.local/state/nix/profiles/home-manager; find ~ -name "*.pre-nix" -o -name "*.backup*" | sort')"
if [ "$before" = "$after" ]; then
  echo "  ok   same home-manager generation, no new backup files"
else
  echo "  FAIL the second run changed the generation or left backups:"
  diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") | sed 's/^/  /'
  exit 1
fi
if grep -q 'Installing Nix' "$LOGS/run2.log"; then echo "  FAIL the second run installed Nix again"; exit 1; fi
echo "  ok   the second run did not reinstall Nix"
# Each block home-manager writes appears once per file.
run 'for rc in ~/.bashrc ~/.zshrc ~/.profile ~/.zshenv; do
  for marker in "dotfiles: tools on PATH" "dotfiles: git identity from gitconfig" "dotfiles: exec fish"; do
    n=$(grep -cF "$marker" "$rc" || true)
    if [ "$n" -gt 1 ]; then echo "  FAIL $rc has $n copies of: $marker"; exit 1; fi
  done
done; echo "  ok   no duplicated shell blocks"'

echo
echo "==> all checks passed"
