#!/usr/bin/env bash
# The Linux check: provision a throwaway Ubuntu container from this working tree with setup.sh, check it with sync.sh, then run both again and check that nothing changed. Needs Docker only; Nix is installed inside the container by setup.sh itself.
#
#   verify/linux.sh                          # this Mac's architecture
#   verify/linux.sh --platform linux/amd64   # the other one, emulated: slower
#   verify/linux.sh --shell                  # provision, then hand you a shell in the box
#
# The container is bare Ubuntu 24.04 with one sudo user and no systemd, like most Coder workspaces. It gets a copy of the files the git flake sees (git's index, with working-tree contents), never a mount, so ignored secrets stay on the host. The assertions are the ones sync.sh runs on any machine.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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

# An emulated architecture (amd64 on Apple silicon) cannot load Nix's seccomp syscall filter, so setup.sh passes this line to the installer there. Real boxes of that architecture do not need it.
EMULATED=()
if [ "$(docker run --rm ${PLATFORM[@]+"${PLATFORM[@]}"} ubuntu:24.04 uname -m)" != "$(uname -m | sed 's/arm64/aarch64/')" ]; then
  EMULATED=(-e "NIX_INSTALLER_EXTRA_CONF=filter-syscalls = false")
fi

# One container for the whole run, so the second pass sees the state the first one left behind.
LOGS="$(mktemp -d)"
CID=""
trap 'if [ -n "$CID" ]; then docker rm -f "$CID" >/dev/null 2>&1 || true; fi; rm -rf "$LOGS"' EXIT INT TERM
CID="$(docker run ${PLATFORM[@]+"${PLATFORM[@]}"} ${EMULATED[@]+"${EMULATED[@]}"} -d ubuntu:24.04 sleep infinity)"
run() { docker exec -u dev -w /home/dev "$CID" bash -lc "$1"; }

echo "==> preparing a bare Ubuntu box (curl, sudo, one user)"
# Only what the box cannot start without: anything more here is something setup.sh is no longer proven to install.
docker exec "$CID" bash -c 'apt-get update -qq && apt-get install -y -qq --no-install-recommends curl ca-certificates sudo >/dev/null && useradd -m -s /bin/bash dev && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev && chmod 440 /etc/sudoers.d/dev' >/dev/null

echo "==> copying the working tree in (secrets stay on the host)"
run 'mkdir -p ~/.config/dotfiles'
# The files the git flake sees, with their working-tree contents: a new file has to be staged, exactly as before a switch.
git -C "$ROOT" ls-files --cached | while IFS= read -r f; do if [ -e "$ROOT/$f" ] || [ -L "$ROOT/$f" ]; then printf '%s\n' "$f"; fi; done |
  COPYFILE_DISABLE=1 tar --no-xattrs --no-fflags -C "$ROOT" -T - -cf - |
  docker exec -i -u dev "$CID" tar -C /home/dev/.config/dotfiles -xf -

if [ "$SHELL_ONLY" = 1 ]; then
  run '~/.config/dotfiles/setup.sh' || true
  docker exec -it -u dev -w /home/dev "$CID" bash -l
  exit 0
fi

# A flag that does not match the machine stops setup.sh before anything changes.
echo "==> setup.sh --macos on Linux"
if run '~/.config/dotfiles/setup.sh --macos' > "$LOGS/wrong.log" 2>&1; then echo "  FAIL setup.sh --macos ran on Linux"; exit 1; fi
if grep -q 'this machine runs linux' "$LOGS/wrong.log" && run '[ ! -e /nix ]'; then echo "  ok   refused, and nothing was installed"; else echo "  FAIL unexpected result:"; cat "$LOGS/wrong.log"; exit 1; fi

# The first run names the platform; the second reads the script from stdin with no arguments, as `curl ... | bash` does.
echo "==> first run: setup.sh --linux"
SECONDS=0
run '~/.config/dotfiles/setup.sh --linux' > "$LOGS/run1.log" 2>&1 || { echo "first run failed:"; tail -40 "$LOGS/run1.log"; exit 1; }
grep -E '^==>|dotfiles:' "$LOGS/run1.log" | sed 's/^/  /'
echo "  first run took ${SECONDS}s"
echo "==> sync.sh --check"
run '~/.config/dotfiles/sync.sh --check'

state() { run 'readlink ~/.local/state/nix/profiles/home-manager; find ~ -name "*.pre-nix" -o -name "*.backup*" | sort'; }
before="$(state)"
[ -n "$(head -1 <<<"$before")" ] || { echo "  FAIL no home-manager generation after the first run"; exit 1; }

echo "==> second run: setup.sh from stdin, then sync.sh (idempotency)"
run 'bash < ~/.config/dotfiles/setup.sh' > "$LOGS/run2.log" 2>&1 || { echo "second run failed:"; tail -40 "$LOGS/run2.log"; exit 1; }
run '~/.config/dotfiles/sync.sh' > "$LOGS/sync.log" 2>&1 || { echo "sync.sh failed:"; grep -E 'FAIL|passed, ' "$LOGS/sync.log" || true; tail -20 "$LOGS/sync.log"; exit 1; }
grep -E 'passed, ' "$LOGS/sync.log" | sed 's/^/  /'
if [ "$before" = "$(state)" ]; then
  echo "  ok   same home-manager generation, no new backup files"
else
  echo "  FAIL the second run changed the generation or left backups"; diff <(printf '%s\n' "$before") <(state) | sed 's/^/  /'; exit 1
fi
if grep -q 'Installing Nix' "$LOGS/run2.log"; then echo "  FAIL the second run installed Nix again"; exit 1; fi
echo "  ok   the second run did not reinstall Nix"
run 'for rc in ~/.bashrc ~/.zshrc ~/.profile ~/.zshenv; do
  for marker in "dotfiles: tools on PATH" "dotfiles: git identity from gitconfig" "dotfiles: exec zsh"; do
    [ -f "$rc" ] || { echo "  FAIL $rc is missing"; exit 1; }
    n=$(grep -cF "$marker" "$rc" || true)
    if [ "$n" -gt 1 ]; then echo "  FAIL $rc has $n copies of: $marker"; exit 1; fi
  done
done; echo "  ok   no duplicated shell blocks"
[ "$(grep -cF "dotfiles: exec zsh" ~/.bashrc || true)" -eq 1 ] || { echo "  FAIL ~/.bashrc does not hand interactive terminals to zsh"; exit 1; }
echo "  ok   ~/.bashrc hands interactive terminals to zsh"'

echo
echo "==> all checks passed"
