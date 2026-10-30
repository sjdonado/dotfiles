#!/usr/bin/env bash
# shellcheck disable=SC2016
# The quoted expressions below are written into shell startup files and must
# expand when those files are sourced, not while provisioning runs.

install_linux_apt() {
  local packages=() package
  while IFS= read -r package; do
    [ -n "$package" ] && packages+=("$package")
  done < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$DOTFILES/packages/linux-apt.txt")
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y
  sudo apt-get install -y "${packages[@]}"
}

replace_managed_block() {
  local file=$1 name=$2 content=$3 start end temporary
  start="# dotfiles: $name start"
  end="# dotfiles: $name end"
  mkdir -p "$(dirname "$file")"
  if [ -L "$file" ]; then
    case "$(readlink "$file")" in
      /nix/store/*)
        if [ ! -e "$file.pre-shell" ] && [ ! -L "$file.pre-shell" ]; then cp -P "$file" "$file.pre-shell"; fi
        rm -f "$file"
        ;;
    esac
  fi
  touch "$file"
  temporary=$(mktemp "$file.XXXXXX")
  awk -v start="$start" -v end="$end" '
    $0 == start { skipping=1; next }
    $0 == end { skipping=0; next }
    !skipping { print }
  ' "$file" > "$temporary"
  printf '%s\n%s\n%s\n' "$start" "$content" "$end" >> "$temporary"
  mv -f "$temporary" "$file"
}

replace_managed_block_top() {
  local file=$1 name=$2 content=$3 start end temporary
  start="# dotfiles: $name start"
  end="# dotfiles: $name end"
  mkdir -p "$(dirname "$file")"
  if [ -L "$file" ]; then
    case "$(readlink "$file")" in
      /nix/store/*)
        if [ ! -e "$file.pre-shell" ] && [ ! -L "$file.pre-shell" ]; then cp -P "$file" "$file.pre-shell"; fi
        rm -f "$file"
        ;;
    esac
  fi
  touch "$file"
  temporary=$(mktemp "$file.XXXXXX")
  printf '%s\n%s\n%s\n' "$start" "$content" "$end" > "$temporary"
  awk -v start="$start" -v end="$end" '
    $0 == start { skipping=1; next }
    $0 == end { skipping=0; next }
    !skipping { print }
  ' "$file" >> "$temporary"
  mv -f "$temporary" "$file"
}

apply_linux_shells() {
  local environment identity interactive file
  environment='export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
ulimit -c 0'
  identity='unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL'
  interactive='if command -v zsh >/dev/null 2>&1 && [ -z "${EXECED_ZSH:-}" ] && [ -t 1 ]; then
  case $- in *i*) export EXECED_ZSH=1; exec zsh ;; esac
fi'
  for file in "$HOME/.profile" "$HOME/.zshenv"; do replace_managed_block "$file" environment "$environment"; done
  replace_managed_block_top "$HOME/.bashrc" path 'export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"'
  replace_managed_block "$HOME/.bashrc" interactive-zsh "$interactive"
  replace_managed_block "$HOME/.zshrc" tracked-config '[ -f "$HOME/.config/dotfiles/zsh/.zshrc" ] && . "$HOME/.config/dotfiles/zsh/.zshrc"'
  replace_managed_block "$HOME/.zshrc" git-identity "$identity"
}

apply_linux() {
  install_linux_apt
  install_linux_node
  export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
  install_linux_user_tools
  install_vendor_agent_clis
  apply_common_links
  [ ! -x /usr/bin/fdfind ] || ln -sfn /usr/bin/fdfind "$HOME/.local/bin/fd"
  [ ! -x /usr/bin/batcat ] || ln -sfn /usr/bin/batcat "$HOME/.local/bin/bat"
  apply_generated_user_state
  apply_linux_shells
  for tool in claude codex; do
    if [ -w /usr/local/bin ]; then ln -sfn "$HOME/.local/bin/$tool" "/usr/local/bin/$tool"
    elif sudo -n true 2>/dev/null; then sudo -n ln -sfn "$HOME/.local/bin/$tool" "/usr/local/bin/$tool"
    else unverified "/usr/local/bin/$tool needs sudo"; fi
  done
}

check_linux_state() {
  local status=0 command shell_command tracked_email
  for command in git zsh mosh python3 wget rg fd bat fzf jq nvim wt node npm bun pnpm uv opencode openspec claude codex; do
    command -v "$command" >/dev/null 2>&1 || { printf 'command missing: %s\n' "$command" >&2; status=1; }
  done
  opencode --version 2>/dev/null | grep -qE '(^| )v?2\.' || { printf 'OpenCode is not v2\n' >&2; status=1; }
  check_link_registry "$(common_link_registry)" || status=1
  [ -f "$HOME/.codex/config.toml" ] || { printf 'generated Codex config is missing\n' >&2; status=1; }
  bat --list-themes 2>/dev/null | grep -q '^GitHub-Dark' || { printf 'bat theme cache is missing GitHub-Dark\n' >&2; status=1; }
  for file in "$HOME/.profile" "$HOME/.zshenv" "$HOME/.bashrc" "$HOME/.zshrc"; do
    if grep -qE '(/nix|\.nix-profile|mise|linuxbrew)' "$file"; then printf 'forbidden provisioning path in %s\n' "$file" >&2; status=1; fi
  done
  shell_command='command -v rg >/dev/null && command -v wt >/dev/null && command -v codex >/dev/null && command -v claude >/dev/null'
  env -i HOME="$HOME" USER="$(id -un)" PATH=/usr/bin:/bin bash -lc "$shell_command" >/dev/null 2>&1 || { printf 'login bash cannot resolve required tools\n' >&2; status=1; }
  env -i HOME="$HOME" USER="$(id -un)" PATH=/usr/bin:/bin bash -c '. "$HOME/.bashrc"; command -v rg >/dev/null && command -v wt >/dev/null' >/dev/null 2>&1 || { printf 'non-login bash cannot resolve required tools\n' >&2; status=1; }
  env -i HOME="$HOME" USER="$(id -un)" PATH=/usr/bin:/bin zsh -c "$shell_command" >/dev/null 2>&1 || { printf 'zsh cannot resolve required tools\n' >&2; status=1; }
  tracked_email=$(git config -f "$DOTFILES/git/.gitconfig" user.email)
  env HOME="$HOME" GIT_AUTHOR_EMAIL=injected@example.invalid bash -lc 'git var GIT_AUTHOR_IDENT' 2>/dev/null | grep -qF "<$tracked_email>" || { printf 'login bash does not use tracked git identity\n' >&2; status=1; }
  return "$status"
}
