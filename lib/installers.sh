#!/usr/bin/env bash

installer_selected() {
  local name=$1
  if [ -n "${DOTFILES_INSTALL_TRACE:-}" ]; then printf '%s\n' "$name" >> "$DOTFILES_INSTALL_TRACE"; fi
  [ "${DOTFILES_PREFLIGHT:-0}" = 1 ]
}

install_vendor_agent_clis() {
  local real_home
  real_home=$(dotfiles_realpath "$HOME")
  mkdir -p "$HOME/.local/bin"
  case "$(dotfiles_realpath "$HOME/.local/bin/claude" 2>/dev/null || true)" in
    "$real_home"/.local/share/claude/*) ;;
    *) installer_selected claude || curl -fsSL https://claude.ai/install.sh | bash ;;
  esac
  case "$(dotfiles_realpath "$HOME/.local/bin/codex" 2>/dev/null || true)" in
    "$real_home"/.codex/packages/standalone/*) ;;
    *) installer_selected codex || curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh ;;
  esac
}

install_linux_user_tools() {
  mkdir -p "$HOME/.local/bin"
  if ! have bun; then curl -fsSL https://bun.sh/install | BUN_INSTALL="$HOME/.local" SHELL=/bin/false bash -s -- bun-v1.4.4; fi
  export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
  if ! have uv; then curl -LsSf https://astral.sh/uv/0.13.6/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh; fi
  if ! have pnpm; then npm install --global --prefix "$HOME/.local" pnpm@12.15.0; fi
  if ! have opencode; then curl -fsSL https://opencode.ai/v2/install | bash -s -- --version 2.2.0 --no-modify-path; fi
  if ! have openspec; then npm install --global --prefix "$HOME/.local" @fission-ai/openspec@1.15.0; fi
  if ! have wt; then
    curl -fsSL https://github.com/max-sixty/worktrunk/releases/download/v0.81.0/worktrunk-installer.sh \
      | env CARGO_HOME="$HOME/.local" WORKTRUNK_NO_MODIFY_PATH=1 WORKTRUNK_DISABLE_UPDATE=1 sh
  fi
}

install_linux_node() {
  local major=0 installer
  if have node; then major=$(node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || printf '0'); fi
  [ "$major" -ge 22 ] && return 0
  installer=$(mktemp)
  curl -fsSL https://deb.nodesource.com/setup_22.x -o "$installer"
  sudo -E bash "$installer"
  rm -f "$installer"
  sudo apt-get install -y nodejs
}

install_macos_user_tools() {
  install_vendor_agent_clis
  if ! have bootdev; then GOBIN="$HOME/.local/bin" go install github.com/bootdotdev/bootdev@latest; fi
  if ! have pss; then curl -fsSL https://raw.githubusercontent.com/sjdonado/pi-skin-sjdonado/main/install.sh | sh; fi
}

apply_generated_user_state() {
  env DOTFILES="$DOTFILES" "$DOTFILES/bin/codex-config" apply >/dev/null
  if have bat; then bat cache --build >/dev/null; fi
}
