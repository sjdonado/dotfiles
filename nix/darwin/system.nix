# macOS system state: Nix itself, the shells, and the defaults. User-level steps are in nix/home/darwin.nix.
{ pkgs, user, ... }:
{
  system.stateVersion = 6;
  # The user whose defaults, Homebrew and login shell this configuration manages.
  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      user
    ];
  };

  # Both put the Nix profiles on PATH for their shells, login or not, through /etc/fish and /etc/zshenv.
  programs.fish.enable = true;
  programs.zsh.enable = true;
  # Lists /run/current-system/sw/bin/fish in /etc/shells, a path that survives every generation.
  environment.shells = [ pkgs.fish ];

  # fish as the login shell. nix-darwin only sets shells for users it creates, and owning this account is not its job, so the switch sets it when it differs. Reading dscl, not $SHELL, which describes the shell that ran the switch.
  system.activationScripts.postActivation.text = ''
    fish=/run/current-system/sw/bin/fish
    if [ "$(/usr/bin/dscl . -read /Users/${user} UserShell | /usr/bin/awk '{print $2}')" != "$fish" ]; then
      echo "dotfiles: setting the login shell of ${user} to $fish"
      /usr/bin/dscl . -create /Users/${user} UserShell "$fish" \
        || echo "dotfiles: login-shell failed; run: chsh -s $fish" >&2
    fi
  '';

  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
  };
}
