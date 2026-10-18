#!/usr/bin/env bash
# The Linux check: provision a throwaway Ubuntu container from this working tree with linux.sh, twice, and assert the result after each run. Needs Docker only; Nix is installed inside the container by linux.sh itself.
#
#   verify/linux.sh                          # this Mac's architecture
#   verify/linux.sh --platform linux/amd64   # the other one, emulated: slower
#   verify/linux.sh --shell                  # provision, then hand you a shell in the box
#
# The container is bare Ubuntu 24.04 with one sudo user and no systemd, like most Coder workspaces. It gets a copy of the files the git flake sees (git's index, with working-tree contents), never a mount, so ignored secrets stay on the host. The same script runs inside the container to assert (VERIFY_STAGE=assert).
set -euo pipefail

# The assertions, run inside the container after linux.sh. Every result is printed; the exit status says whether any failed.
assert_box() {
  set +e
  DOTFILES="$HOME/.config/dotfiles"
  PASS=0 FAIL=0
  ok()   { printf '  ok   %s\n' "$1"; PASS=$((PASS+1)); }
  bad()  { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL+1)); }
  group() { printf '\n== %s\n' "$1"; }

  # A tool counts as installed only if it runs: a wrapper whose setup never happened is on PATH and still broken. Some tools spell the version flag differently, hence the optional second argument.
  runs() {
    local cmd=$1 flag=${2:---version} out
    if ! command -v "$cmd" >/dev/null 2>&1; then bad "$cmd not on PATH"; return; fi
    if out=$("$cmd" $flag 2>&1 </dev/null) && [ -n "$out" ]; then
      ok "$cmd -> $(printf '%s' "$out" | head -1 | cut -c1-50)"
    else
      bad "$cmd on PATH but '$cmd $flag' failed: $(printf '%s' "$out" | head -1 | cut -c1-60)"
    fi
  }

  # The link has to resolve to the file in the working tree: a copy with the same contents fails.
  linked() {
    local link=$1 target=$2
    if [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]; then
      ok "${link#"$HOME"/} -> ${target#"$DOTFILES"/}"
    else
      bad "${link#"$HOME"/} is not a link to ${target#"$DOTFILES"/} (readlink -f: $(readlink -f "$link" 2>/dev/null || echo none))"
    fi
  }

  group "Nix"
  # Upstream Nix, not Determinate Nix: nix-darwin manages nix.conf on macOS, and both platforms install the same way.
  if v=$(nix --version 2>&1) && ! grep -qi determinate <<<"$v"; then ok "upstream Nix: $v"; else bad "not upstream Nix: $v"; fi

  group "declared tools"
  for c in git zsh mosh python3 pip wget rg fd bat fzf jq nvim wt node bun pnpm uv claude codex opencode openspec; do runs "$c"; done
  if opencode --version 2>/dev/null | grep -q 'v2\.'; then ok "OpenCode is v2"; else bad "OpenCode is not v2 ($(opencode --version 2>&1 | head -1))"; fi

  # Skipped with the full neovim setup (nix/home/common.nix).
  # group "language servers and formatters (from Nix, not Mason)"
  # for c in astro-ls basedpyright clangd crystalline lua-language-server vtsls yaml-language-server black gofumpt isort prettierd ruff stylua; do runs "$c"; done
  # runs gopls version
  # # These servers have no version flag; each has to answer an LSP initialize request with its capabilities. They run in parallel, since each needs a few seconds to answer.
  # initialize='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'
  # # Captured before matching: under pipefail, the server's exit status after stdin closes would override grep's.
  # answers() {
  #   local out
  #   out=$({ printf 'Content-Length: %d\r\n\r\n%s' "${#initialize}" "$initialize"; sleep 5; } | timeout 15 "$1" --stdio 2>/dev/null)
  #   grep -q '"capabilities"' <<<"$out"
  # }
  # lsp_dir=$(mktemp -d)
  # for c in vscode-css-language-server vscode-eslint-language-server vscode-json-language-server svelteserver tailwindcss-language-server; do
  #   { if answers "$c"; then echo "ok"; else echo "fail"; fi > "$lsp_dir/$c"; } &
  # done
  # wait
  # for f in "$lsp_dir"/*; do
  #   c=$(basename "$f")
  #   if [ "$(cat "$f")" = ok ]; then ok "$c answers an LSP initialize request"; else bad "$c does not answer an LSP initialize request"; fi
  # done
  # rm -rf "$lsp_dir"
  # for c in golangci-lint-langserver goimports; do
  #   if command -v "$c" >/dev/null 2>&1; then ok "$c on PATH (has no version flag)"; else bad "$c not on PATH"; fi
  # done
  if nvim --headless -c 'if v:errmsg != "" | cquit 1 | endif' -c 'qa' >/dev/null 2>&1; then ok "nvim starts headless without errors"; else bad "nvim reports errors on a headless start"; fi

  group "linked config"
  linked "$HOME/.gitconfig"                       "$DOTFILES/git/.gitconfig"
  for f in "$DOTFILES/bat/themes/"*; do linked "$HOME/.config/bat/themes/$(basename "$f")" "$f"; done
  for f in "$DOTFILES/bin/"*; do linked "$HOME/.local/bin/$(basename "$f")" "$f"; done
  # linked "$HOME/.config/nvim"                     "$DOTFILES/nvim"  # skipped with the full neovim setup
  linked "$HOME/.config/worktrunk/config.toml"    "$DOTFILES/worktrunk/config.toml"
  linked "$HOME/.config/zed/settings.json"        "$DOTFILES/zed/settings.json"
  linked "$HOME/.config/zed/keymap.json"          "$DOTFILES/zed/keymap.json"
  linked "$HOME/.claude/settings.json"            "$DOTFILES/claude/settings.json"
  linked "$HOME/.claude/skills"                   "$DOTFILES/agents/skills"
  linked "$HOME/.claude/CLAUDE.md"                "$DOTFILES/agents/AGENTS.md"
  linked "$HOME/.agents/skills"                   "$DOTFILES/agents/skills"
  linked "$HOME/.codex/AGENTS.md"                 "$DOTFILES/agents/AGENTS.md"
  linked "$HOME/.config/opencode/opencode.json"   "$DOTFILES/opencode/opencode.json"
  linked "$HOME/.config/opencode/cli.json"        "$DOTFILES/opencode/cli.json"
  linked "$HOME/.config/opencode/AGENTS.md"       "$DOTFILES/opencode/AGENTS.md"
  linked "$HOME/.config/opencode/plugins/no-foreground-wait.ts" "$DOTFILES/opencode/plugins/no-foreground-wait.ts"
  linked "$HOME/.local/state/opencode/kv.json"    "$DOTFILES/opencode/kv.json"
  linked "$HOME/.pi/agent/settings.json"          "$DOTFILES/pi/settings.json"
  linked "$HOME/.pi/agent/mcp.json"               "$DOTFILES/pi/mcp.json"
  linked "$HOME/.pi/agent/AGENTS.md"              "$DOTFILES/agents/AGENTS.md"

  group "generated by the setup steps"
  if [ -f "$HOME/.codex/config.toml" ]; then ok "codex-config wrote ~/.codex/config.toml"; else bad "~/.codex/config.toml missing"; fi
  if bat --list-themes 2>/dev/null | grep -q '^GitHub-Dark'; then ok "bat resolves the GitHub-Dark theme from its cache"; else bad "bat cache lacks GitHub-Dark"; fi

  group "non-interactive shells resolve the tools"
  # This is the shell an agent hook or a herdr pane running a command gets: no rc file beyond what these read.
  for c in rg nvim wt codex claude; do
    if bash -lc "command -v $c" >/dev/null 2>&1; then ok "login bash finds $c"; else bad "login bash cannot find $c"; fi
    # `ssh host command` runs a non-login, non-interactive bash, which reads only ~/.bashrc, up to its interactive guard.
    if env -i HOME="$HOME" bash -c ". ~/.bashrc >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then ok "a non-login bash sourcing ~/.bashrc finds $c"; else bad "~/.bashrc does not put $c on PATH before its interactive guard"; fi
    if env -i HOME="$HOME" bash -c ". ~/.profile >/dev/null 2>&1; command -v $c" >/dev/null 2>&1; then
      ok "a bare shell sourcing ~/.profile finds $c"
    else
      bad "~/.profile does not put $c on PATH"
    fi
    # zsh comes from the Nix profile (Ubuntu has none), so it is named by path: env -i leaves no PATH to find it with.
    if env -i HOME="$HOME" "$HOME/.nix-profile/bin/zsh" -c "command -v $c" >/dev/null 2>&1; then ok "zsh -c finds $c (via ~/.zshenv)"; else bad "zsh -c cannot find $c"; fi
  done
  if [ "$(env -i HOME="$HOME" bash -lc 'command -v claude')" = "$HOME/.nix-profile/bin/claude" ]; then
    ok "claude resolves to the Nix profile, ahead of ~/.local/bin"
  else
    bad "claude resolves to $(env -i HOME="$HOME" bash -lc 'command -v claude'), not the Nix profile"
  fi
  # An interactive terminal execs zsh, whose ~/.zshrc sources zsh/.zshrc: the wtc alias is defined only there.
  if env -i HOME="$HOME" TERM=dumb "$HOME/.nix-profile/bin/zsh" -ic 'alias wtc >/dev/null && whence rg nvim >/dev/null' </dev/null >/dev/null 2>&1; then ok "interactive zsh runs zsh/.zshrc and finds rg and nvim"; else bad "interactive zsh does not run zsh/.zshrc or cannot find rg or nvim"; fi

  group "git identity comes from the tracked gitconfig"
  tracked=$(git config -f "$DOTFILES/git/.gitconfig" user.email)
  if [ -n "$tracked" ] && env GIT_AUTHOR_EMAIL=injected@coder bash -lc 'git var GIT_AUTHOR_IDENT' 2>/dev/null | grep -qF "<$tracked>"; then
    ok "an injected GIT_AUTHOR_EMAIL gives way to the tracked user.email"
  else
    bad "the login shell does not use the tracked user.email ($tracked)"
  fi
  # Coder's env.sh sets the identity again after ~/.zshenv; zsh/.zshrc must unset it after sourcing that file.
  if [ -n "$tracked" ] && env GIT_AUTHOR_EMAIL=injected@coder TERM=dumb "$HOME/.nix-profile/bin/zsh" -ic 'git var GIT_AUTHOR_IDENT' </dev/null 2>/dev/null | grep -qF "<$tracked>"; then
    ok "interactive zsh uses the tracked user.email"
  else
    bad "interactive zsh does not use the tracked user.email ($tracked)"
  fi

  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}

if [ "${VERIFY_STAGE:-}" = assert ]; then
  assert_box
  exit
fi

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

# An emulated architecture (amd64 on Apple silicon) cannot load Nix's seccomp syscall filter, so linux.sh passes this line to the installer there. Real boxes of that architecture do not need it.
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
# Only what the box cannot start without: anything more here is something linux.sh is no longer proven to install.
docker exec "$CID" bash -c 'apt-get update -qq && apt-get install -y -qq --no-install-recommends curl ca-certificates sudo >/dev/null && useradd -m -s /bin/bash dev && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev && chmod 440 /etc/sudoers.d/dev' >/dev/null

echo "==> copying the working tree in (secrets stay on the host)"
run 'mkdir -p ~/.config/dotfiles'
# The files the git flake sees, with their working-tree contents: a new file has to be staged, exactly as before a switch.
git -C "$ROOT" ls-files --cached | while IFS= read -r f; do if [ -e "$ROOT/$f" ] || [ -L "$ROOT/$f" ]; then printf '%s\n' "$f"; fi; done |
  COPYFILE_DISABLE=1 tar --no-xattrs --no-fflags -C "$ROOT" -T - -cf - |
  docker exec -i -u dev "$CID" tar -C /home/dev/.config/dotfiles -xf -

if [ "$SHELL_ONLY" = 1 ]; then
  run '~/.config/dotfiles/linux.sh' || true
  docker exec -it -u dev -w /home/dev "$CID" bash -l
  exit 0
fi

echo "==> first run: linux.sh"
SECONDS=0
run '~/.config/dotfiles/linux.sh' > "$LOGS/run1.log" 2>&1 || { echo "first run failed:"; tail -40 "$LOGS/run1.log"; exit 1; }
grep -E '^==>|dotfiles:' "$LOGS/run1.log" | sed 's/^/  /'
echo "  first run took ${SECONDS}s"
run 'VERIFY_STAGE=assert ~/.config/dotfiles/verify/linux.sh'

state() { run 'readlink ~/.local/state/nix/profiles/home-manager; find ~ -name "*.pre-nix" -o -name "*.backup*" | sort'; }
before="$(state)"
[ -n "$(head -1 <<<"$before")" ] || { echo "  FAIL no home-manager generation after the first run"; exit 1; }

echo "==> second run: linux.sh again (idempotency)"
run '~/.config/dotfiles/linux.sh' > "$LOGS/run2.log" 2>&1 || { echo "second run failed:"; tail -40 "$LOGS/run2.log"; exit 1; }
run 'VERIFY_STAGE=assert ~/.config/dotfiles/verify/linux.sh'
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
