# Linux only: the shell files, on any distribution with Nix installed. home-manager owns ~/.profile, ~/.bash_profile, ~/.bashrc, ~/.zshenv and ~/.zshrc; the first switch keeps one backup of each original (`-b pre-nix`).
#
# Environment goes in the files a shell reads however it was started (~/.profile for login sh and bash, ~/.zshenv for every zsh), plus the top of ~/.bashrc, which runs before its interactive guard. An agent hook, a tool running a command and `ssh host command` read nothing else.
#
# The login shell stays POSIX: Coder runs its agent and metadata scripts through it, so interactive terminals exec into zsh instead, which runs zsh/.zshrc, the same interactive setup macOS uses.
{ lib, pkgs, dotfiles, ... }:
let
  environment = ''
    # dotfiles: tools on PATH. The Nix profile comes from the daemon's profile script, which /etc/profile only runs for login shells.
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    # ~/.local/bin (this repository's scripts, Claude Code and Codex) right after the Nix profiles: behind them, so nothing there shadows a declared tool, and ahead of the system directories, where a base image may ship its own claude (Coder's has one in /usr/local/bin) that would hide the self-updating install.
    _path=$(printf '%s' "$PATH" | ${pkgs.gawk}/bin/awk -v lb="$HOME/.local/bin" -v home="$HOME" 'BEGIN { RS = ":" }
      { sub(/\n$/, "") }
      $0 == lb || $0 == "" { next }
      !done && $0 !~ /^\/nix\// && index($0, home "/.nix-profile/") != 1 && index($0, home "/.local/state/nix/") != 1 { out = out sep lb; sep = ":"; done = 1 }
      { out = out sep $0; sep = ":" }
      END { if (!done) out = out sep lb; printf "%s", out }')
    [ -n "$_path" ] && export PATH="$_path"
    unset _path
  '';
  # Coder injects a git identity into every process it spawns, and env beats ~/.gitconfig. GIT_ASKPASS and GIT_SSH_COMMAND stay: those are how Coder brokers git auth.
  identity = ''
    # dotfiles: git identity from gitconfig, not Coder's injected env
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  '';
  # core_pattern is the bare name `core` on these boxes, so a crash writes the dump into the process's cwd, which is usually a repository.
  noCores = ''
    # dotfiles: no core dumps
    ulimit -c 0
  '';
  # Never for non-interactive agent or metadata scripts, which must stay POSIX: the TTY test keeps them out.
  execZsh = ''
    # dotfiles: exec zsh for interactive terminals only
    if command -v zsh >/dev/null 2>&1 && [ -z "$EXECED_ZSH" ] && [ -t 1 ]; then
      case $- in
        *i*) export EXECED_ZSH=1; exec zsh ;;
      esac
    fi
  '';
in
{
  # What linux.sh used to install from the distribution, declared so a fresh box needs nothing but Nix.
  home.packages = [
    (pkgs.python3.withPackages (ps: [ ps.pip ]))
    pkgs.wget
  ];

  programs.bash = {
    enable = true;
    profileExtra = environment + identity + noCores;
    # Before ~/.bashrc's interactive guard, so the interactive non-login case (which reads no profile) has the tools too.
    bashrcExtra = environment;
    initExtra = execZsh;
  };

  programs.zsh = {
    enable = true;
    envExtra = environment + identity + noCores;
    # zsh/.zshrc is the interactive setup macOS uses too; it also sources Coder's env.sh and then unsets the identity Coder injects.
    initContent = ''
      [ -f "$HOME/.config/dotfiles/zsh/.zshrc" ] && . "$HOME/.config/dotfiles/zsh/.zshrc"
    '';
    # zsh/.zshrc runs compinit itself.
    enableCompletion = false;
  };

  # Claude Code and Codex for every process on the box, not only shells that read the files above: /usr/local/bin/<tool> links to the self-updating install in ~/.local/bin, replacing a base image's own copy (Coder's ships a stale claude there). Needs passwordless sudo, which Coder workspaces have; without it the step says it skipped.
  home.activation.agentCliLinks = dotfiles.step "agent-cli-links" ''
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    if [ -w /usr/local/bin ]; then as=""; elif sudo -n true 2>/dev/null; then as="sudo -n"; else
      echo "dotfiles: skipped agent-cli-links: /usr/local/bin is not writable and sudo needs a password"
      exit 0
    fi
    for tool in claude codex; do
      [ -e "$HOME/.local/bin/$tool" ] || continue
      [ "$(readlink /usr/local/bin/$tool 2>/dev/null || true)" = "$HOME/.local/bin/$tool" ] || $as ln -sfn "$HOME/.local/bin/$tool" /usr/local/bin/$tool
    done
  '' // { after = [ "linkGeneration" "agentClis" ]; };
}
