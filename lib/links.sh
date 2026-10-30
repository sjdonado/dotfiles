#!/usr/bin/env bash

DOTFILES=${DOTFILES:-$HOME/.config/dotfiles}

managed_link() {
  local source=$1 destination=$2 backup
  source=$(dotfiles_realpath "$source")
  mkdir -p "$(dirname "$destination")"
  if [ -L "$destination" ] && [ "$(dotfiles_realpath "$destination" 2>/dev/null || true)" = "$source" ]; then
    return 0
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    backup="$destination.pre-shell"
    if [ ! -e "$backup" ] && [ ! -L "$backup" ]; then
      mv "$destination" "$backup"
    else
      rm -f "$destination"
    fi
  fi
  ln -s "$source" "$destination"
}

managed_directory_files() {
  local source_dir=$1 destination_dir=$2 source destination target
  mkdir -p "$destination_dir"
  for destination in "$destination_dir"/*; do
    [ -L "$destination" ] || continue
    target=$(readlink "$destination")
    case "$target" in
      "$(dotfiles_realpath "$source_dir")"/*)
        [ -e "$source_dir/$(basename "$destination")" ] || rm -f "$destination"
        ;;
    esac
  done
  for source in "$source_dir"/*; do
    [ -e "$source" ] || continue
    managed_link "$source" "$destination_dir/$(basename "$source")"
  done
}

common_link_registry() {
  cat <<'EOF'
git/.gitconfig|.gitconfig
worktrunk/config.toml|.config/worktrunk/config.toml
zed/settings.json|.config/zed/settings.json
zed/keymap.json|.config/zed/keymap.json
claude/settings.json|.claude/settings.json
agents/skills|.claude/skills
agents/AGENTS.md|.claude/CLAUDE.md
agents/skills|.agents/skills
agents/AGENTS.md|.codex/AGENTS.md
opencode/opencode.json|.config/opencode/opencode.json
opencode/cli.json|.config/opencode/cli.json
opencode/AGENTS.md|.config/opencode/AGENTS.md
opencode/plugins/no-foreground-wait.ts|.config/opencode/plugins/no-foreground-wait.ts
opencode/kv.json|.local/state/opencode/kv.json
pi/settings.json|.pi/agent/settings.json
pi/mcp.json|.pi/agent/mcp.json
agents/AGENTS.md|.pi/agent/AGENTS.md
EOF
}

macos_link_registry() {
  cat <<'EOF'
zsh/.zshrc|.zshrc
shell/environment.sh|.zshenv
shell/environment.sh|.profile
shell/environment.sh|.bash_profile
docker/config.json|.docker/config.json
.ssh/config|.ssh/config
macos/browser-router.json|.config/browser-router/config.json
macos/handy/settings_store.json|Library/Application Support/com.pais.handy/settings_store.json
EOF
}

apply_link_registry() {
  local registry=$1 source destination
  while IFS='|' read -r source destination; do
    [ -n "$source" ] || continue
    managed_link "$DOTFILES/$source" "$HOME/$destination"
  done <<<"$registry"
}

apply_common_links() {
  apply_link_registry "$(common_link_registry)"
  managed_directory_files "$DOTFILES/bin" "$HOME/.local/bin"
  managed_directory_files "$DOTFILES/bat/themes" "$HOME/.config/bat/themes"
}

apply_macos_links() {
  apply_link_registry "$(macos_link_registry)"
  touch "$HOME/.hushlogin"
}

check_link_registry() {
  local registry=$1 source destination actual expected status=0
  while IFS='|' read -r source destination; do
    [ -n "$source" ] || continue
    actual=$(dotfiles_realpath "$HOME/$destination" 2>/dev/null || true)
    expected=$(dotfiles_realpath "$DOTFILES/$source")
    if [ "$actual" != "$expected" ] || [ ! -L "$HOME/$destination" ]; then
      printf 'not linked: %s -> %s\n' "$HOME/$destination" "$DOTFILES/$source" >&2
      status=1
    fi
  done <<<"$registry"
  return "$status"
}
