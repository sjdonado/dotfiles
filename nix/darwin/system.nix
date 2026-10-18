# macOS system state: Nix itself, the shells, and the defaults. User-level steps are in nix/home/darwin.nix.
{
  lib,
  user,
  users,
  ...
}:
{
  system.stateVersion = 6;
  # The user who owns Homebrew and the system-wide settings; per-user settings are in nix/home/darwin.nix, applied to every user.
  system.primaryUser = user;
  users.users = lib.genAttrs users (u: { home = "/Users/${u}"; });

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ] ++ users;
  };

  # zsh is every account's login shell: macOS ships it, so no login depends on the Nix store. nix-darwin puts the Nix profiles on its PATH for every zsh, login or not, through /etc/zshenv; ~/.local/bin (this repository's scripts, pss) goes after them, so a binary an old installer left there cannot shadow a declared one.
  programs.zsh.enable = true;
  # /etc/zshrc would run compinit, which prompts in every account that does not own Homebrew's completion directories (they belong to the primary account). zsh/.zshrc runs it instead, accepting directories another admin account owns.
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.enableBashCompletion = false;
  programs.zsh.shellInit = ''
    case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$PATH:$HOME/.local/bin" ;; esac
  '';

  # nix-darwin only sets shells for users it creates, and owning these accounts is not its job, so the switch sets each one when it differs. This also repairs a login shell that points into a Nix store path that is gone. Reading dscl, not $SHELL, which describes the shell that ran the switch.
  system.activationScripts.postActivation.text = lib.concatMapStrings (u: ''
    # An account removed from macOS but still listed in flake.nix is skipped: `dscl -create` would leave a partial user record.
    if ! /usr/bin/dscl . -read /Users/${u} >/dev/null 2>&1; then
      echo "dotfiles: ${u} is listed in flake.nix but has no macOS account; remove it from the list"
    elif [ "$(/usr/bin/dscl . -read /Users/${u} UserShell | /usr/bin/awk '{print $2}')" != /bin/zsh ]; then
      echo "dotfiles: setting the login shell of ${u} to /bin/zsh"
      /usr/bin/dscl . -create /Users/${u} UserShell /bin/zsh \
        || echo "dotfiles: login-shell failed; run: sudo chsh -s /bin/zsh ${u}" >&2
    fi
  '') users;
}
