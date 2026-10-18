# Linux only: the shell files, on any distribution with Nix installed. home-manager owns ~/.profile, ~/.bash_profile, ~/.bashrc, ~/.zshenv and ~/.zshrc; the first switch keeps one backup of each original (`-b pre-nix`).
#
# Environment goes in the files a shell reads however it was started (~/.profile for login sh and bash, ~/.zshenv for every zsh), plus the top of ~/.bashrc, which runs before its interactive guard. An agent hook, a herdr pane running a command and `ssh host command` read nothing else.
#
# The login shell stays POSIX: Coder runs its agent and metadata scripts through it, so interactive terminals exec into zsh instead, which runs zsh/.zshrc, the same interactive setup macOS uses.
{ pkgs, ... }:
let
  environment = ''
    # dotfiles: tools on PATH. The Nix profile comes from the daemon's profile script, which /etc/profile only runs for login shells.
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    # After the Nix profile, so a binary an old installer left in ~/.local/bin (claude's did) cannot shadow the declared one. This repository's own scripts there have names nothing else uses.
    case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$PATH:$HOME/.local/bin" ;; esac
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
}
