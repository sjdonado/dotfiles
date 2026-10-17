# macOS system state: Nix itself, the shells, and the defaults. User-level steps are in nix/home/darwin.nix.
{
  lib,
  pkgs,
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

  # Both put the Nix profiles on PATH for their shells, login or not, through /etc/fish and /etc/zshenv.
  programs.fish.enable = true;
  programs.zsh.enable = true;
  # Lists /run/current-system/sw/bin/fish in /etc/shells, a path that survives every generation.
  environment.shells = [ pkgs.fish ];

  # fish as the login shell of every user. nix-darwin only sets shells for users it creates, and owning these accounts is not its job, so the switch sets each one when it differs. Reading dscl, not $SHELL, which describes the shell that ran the switch.
  system.activationScripts.postActivation.text = lib.concatMapStrings (u: ''
    fish=/run/current-system/sw/bin/fish
    if [ "$(/usr/bin/dscl . -read /Users/${u} UserShell | /usr/bin/awk '{print $2}')" != "$fish" ]; then
      echo "dotfiles: setting the login shell of ${u} to $fish"
      /usr/bin/dscl . -create /Users/${u} UserShell "$fish" \
        || echo "dotfiles: login-shell failed; run: sudo chsh -s $fish ${u}" >&2
    fi
  '') users;
}
