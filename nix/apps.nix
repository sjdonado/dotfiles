# The two commands that change a machine: `nix run .#sync` applies the declaration (a switch), `nix run .#upgrade` moves the pins and then syncs. Both take --dry-run, which prints each step instead of running it.
{ inputs }:
pkgs:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  # The repository is passed as a plain directory, which Nix reads as a git flake: only tracked files enter the store, so gitignored secrets (.env, .ssh/private.conf) never do. A new file has to be staged (`git add`) before a switch sees it.
  common = ''
    # Fixed: the configuration links into this path (nix/home/common.nix).
    DOTFILES="$HOME/.config/dotfiles"
    dry=0
    for arg in "$@"; do
      case "$arg" in
        --dry-run) dry=1 ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
      esac
    done
    step() {
      if [ "$dry" = 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi
    }
  '';
  # Only the primary account (the first in this Mac's list in flake.nix) switches, as in macos.sh, and only once it owns everything under /opt/homebrew: macos.sh hands Homebrew over after the primary account changes. Checked before anything changes, including flake.lock. /usr/bin tools, not the coreutils on this script's PATH: GNU stat reads -f differently.
  preflight = lib.optionalString isDarwin ''
    config="$(/usr/sbin/scutil --get LocalHostName)"
    primary="$(/usr/bin/sed -n "s/.*\"$config\" = darwin \[ *\"\([^\"]*\)\".*/\1/p" "$DOTFILES/flake.nix")"
    if [ -z "$primary" ]; then
      echo "flake.nix has no darwinConfigurations entry for this Mac ($config)." >&2
      exit 1
    fi
    if [ "$(/usr/bin/id -un)" != "$primary" ]; then
      echo "Run this from the primary account, $primary (flake.nix, darwinConfigurations.$config)." >&2
      exit 1
    fi
    if [ -d /opt/homebrew ] && [ -n "$(/usr/bin/find /opt/homebrew ! -user "$primary" -print -quit 2>/dev/null)" ]; then
      echo "Part of /opt/homebrew belongs to another account; run ~/.config/dotfiles/macos.sh once to hand it to $primary." >&2
      exit 1
    fi
  '';
  syncCommand =
    if isDarwin then
      ''
        step sudo ${inputs.nix-darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild switch --flake "$DOTFILES#$config"
      ''
    else
      # -b keeps one backup of a file home-manager takes over, such as the distribution's ~/.profile on the first switch.
      # home-manager reads the user from $USER (flake.nix), which a non-login shell or `docker exec` may not set.
      ''
        USER="''${USER:-$(id -un)}"
        export USER
        # As overwriteBackup on macOS: a tool that replaced its link with a real file is backed up again instead of stopping the switch.
        export HOME_MANAGER_BACKUP_OVERWRITE=1
        case "$(uname -m)" in arm64 | aarch64) arch=aarch64 ;; *) arch=x86_64 ;; esac
        step ${
        inputs.home-manager.packages.${system}.home-manager
      }/bin/home-manager switch --flake "$DOTFILES#linux-$arch" --impure -b pre-nix
      '';

  sync = pkgs.writeShellApplication {
    name = "sync";
    runtimeInputs = [ pkgs.coreutils ];
    text = common + preflight + syncCommand;
  };

  upgrade = pkgs.writeShellApplication {
    name = "upgrade";
    runtimeInputs = [ pkgs.coreutils ];
    text = common + preflight + ''
      # Every input in flake.lock: nixpkgs, home-manager, nix-darwin, nix-homebrew, each Homebrew tap and the pinned sources.
      step nix flake update --flake "$DOTFILES"
      # Neovim plugins are pinned by nvim/nvim-pack-lock.json, which this rewrites in the repository. nvim exits 0 when a -c command errors, so failures report through cquit. Skipped with the full neovim setup (nvim/ is not linked).
      # step nvim --headless -c 'lua local ok, err = pcall(vim.pack.update, nil, { force = true }); if not ok then io.stderr:write(tostring(err), "\n"); vim.cmd.cquit(1) end' -c 'if v:errmsg != "" | cquit 1 | endif' -c 'qa'
    '' + syncCommand + ''

      [ "$dry" = 1 ] || echo "Upgraded. Review and commit the lockfile diffs: git -C \"$DOTFILES\" diff flake.lock"
    '';
  };
in
{
  sync = {
    type = "app";
    program = lib.getExe sync;
    meta.description = "Apply the declaration to this machine";
  };
  upgrade = {
    type = "app";
    program = lib.getExe upgrade;
    meta.description = "Update every pinned input, then sync";
  };
}
