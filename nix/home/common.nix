# What every machine gets, macOS and Linux alike: the shared command-line tools, the links into this repository, and the setup steps that are not packages.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  repo = "${config.home.homeDirectory}/.config/dotfiles";
  src = ../..;

  # A live link into the working tree, not a copy in the Nix store, so editing a config here takes effect without a switch and tools that write back (nvim's plugin lockfile, opencode kv.json, pi settings.json) change the tracked file. Whatever was at the path before the first switch is kept once as <path>.pre-nix (`-b pre-nix` on Linux, `backupFileExtension` on macOS).
  live = path: { source = config.lib.file.mkOutOfStoreSymlink "${repo}/${path}"; };
  # One live link per file of a repository directory, for directories where tools keep their own files beside ours (fish functions, ~/.local/bin, themes).
  liveEach =
    dir: target:
    lib.mapAttrs' (name: _: lib.nameValuePair "${target}/${name}" (live "${dir}/${name}")) (
      builtins.readDir (src + "/${dir}")
    );

  # A setup step that is not a package or a link. It runs after the links exist and stops at its first failing command, and a failure prints the step's name and lets the other steps run. A step that skips says so itself.
  step =
    name: script:
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if ! run ${pkgs.writeShellScript "dotfiles-${name}" ("set -euo pipefail\n" + script)}; then
        warnEcho "dotfiles: ${name} failed; the other steps still ran. Fix it, then switch again."
      fi
    '';
  binPath = pkgs: "export PATH=${lib.makeBinPath pkgs}:$PATH";
  codex = pkgs.callPackage ../pkgs/codex.nix { }; # prebuilt; nixpkgs compiles it
  # The release binary on macOS, where T3 Code flags a version older than the latest; nixpkgs elsewhere.
  claude-code = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.callPackage ../pkgs/claude-code.nix { } else pkgs.claude-code;
in
{
  # Shared with nix/home/darwin.nix.
  _module.args.dotfiles = { inherit repo live step; };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Shell, editor and the tools the configs call.
    git
    fish
    mosh
    ripgrep
    fd
    bat
    fzf
    jq
    # neovim is plain: git's editor, without nvim/ (whose init.lua installs language servers through Mason). The main editor is Zed with T3 Code. Uncomment these and the nvim link and nvimPlugins step below to restore the full setup.
    neovim
    # lazygit
    # tree-sitter
    worktrunk
    nodejs # the current LTS
    bun
    pnpm
    uv

    # Agent harnesses and their tools.
    claude-code
    codex
    (callPackage ../pkgs/opencode.nix { }) # v2; nixpkgs still has v1
    openspec
    # Skipped: herdr is not in use (owner's decision, 2026-10-17). Uncomment to bring it back.
    # herdr

    # Skipped with the full neovim setup.
    # # Language servers and formatters nvim/init.lua starts. They come from here instead of Mason, which downloads binaries outside this declaration.
    # astro-language-server
    # basedpyright
    # clang-tools # clangd
    # crystalline
    # vscode-langservers-extracted # cssls, eslint, jsonls
    # gopls
    # golangci-lint-langserver
    # lua-language-server
    # svelte-language-server
    # tailwindcss-language-server
    # vtsls
    # yaml-language-server
    # black
    # gofumpt
    # gotools # goimports
    # isort
    # prettierd
    # ruff
    # stylua
  ];

  home.file = {
    ".gitconfig" = live "git/.gitconfig";
    ".claude/settings.json" = live "claude/settings.json";
    ".claude/skills" = live "agents/skills";
    ".claude/CLAUDE.md" = live "agents/AGENTS.md";
    ".agents/skills" = live "agents/skills";
    ".codex/AGENTS.md" = live "agents/AGENTS.md";
    ".local/state/opencode/kv.json" = live "opencode/kv.json";
    ".pi/agent/settings.json" = live "pi/settings.json";
    ".pi/agent/mcp.json" = live "pi/mcp.json";
    ".pi/agent/AGENTS.md" = live "agents/AGENTS.md";
    # GUI apps (T3 Code, Zed) keep the PATH they launched with and look for the agents in ~/.local/bin, where the curl installers put them. These links make that path the Nix build too. Forced: home-manager backs up files but refuses to replace a foreign symlink, which is what a curl installer leaves there.
    ".local/bin/claude" = { source = "${claude-code}/bin/claude"; force = true; };
    ".local/bin/codex" = { source = "${codex}/bin/codex"; force = true; };
  }
  // liveEach "bin" ".local/bin";

  xdg.configFile = {
    "fish/config.fish" = live "fish/config.fish";
    "ghostty/config" = live "ghostty/config";
    # The directory, not its files: init.lua resolves nvim-pack-lock.json relative to the config directory it loaded from. Skipped with the full neovim setup.
    # "nvim" = live "nvim";
    # Only config.toml: herdr keeps sockets, logs and session.json in the same directory. Skipped: herdr is not in use (owner's decision, 2026-10-17). Uncomment to bring it back.
    # "herdr/config.toml" = live "herdr/config.toml";
    "worktrunk/config.toml" = live "worktrunk/config.toml";
    "zed/settings.json" = live "zed/settings.json";
    "zed/keymap.json" = live "zed/keymap.json";
    "opencode/opencode.json" = live "opencode/opencode.json";
    "opencode/cli.json" = live "opencode/cli.json";
    "opencode/AGENTS.md" = live "opencode/AGENTS.md";
    # The file, not plugins/: herdr writes its own plugin beside this one.
    "opencode/plugins/no-foreground-wait.ts" = live "opencode/plugins/no-foreground-wait.ts";
  }
  // liveEach "fish/functions" "fish/functions"
  // liveEach "ghostty/themes" "ghostty/themes"
  // liveEach "bat/themes" "bat/themes";

  home.activation = {
    # Skipped: herdr is not in use (owner's decision, 2026-10-17). Uncomment to bring it back.
    # # claude/settings.json declares a SessionStart hook running herdr's agent-state script, which herdr installs. The installer also rewrites settings.json, so it runs before the link exists (the link then replaces the file it wrote), and only while the hook is missing; afterwards it would write through the link into the tracked file.
    # herdrClaude = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    #   if [ -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
    #     verboseEcho "dotfiles: herdr claude integration already installed"
    #   elif ! { run mkdir -p "$HOME/.claude" && run ${pkgs.herdr}/bin/herdr integration install claude >/dev/null; }; then
    #     warnEcho "dotfiles: herdr-claude failed; the SessionStart hook will no-op. Switch again to retry."
    #   fi
    # '';

    # herdrOpencode = step "herdr-opencode" ''
    #   if [ -f "$HOME/.config/opencode/herdr-opencode/tui.js" ]; then exit 0; fi
    #   ${pkgs.herdr}/bin/herdr integration install opencode
    # '';

    # # Local workflow plugins are linked from this repository; the two remote ones are pinned by ref. Both need a running herdr server. A stamp of the plugin set and the refs skips the whole step while neither changed, so a switch does not reinstall them.
    # herdrPlugins = step "herdr-plugins" ''
    #   ${binPath [
    #     pkgs.herdr
    #     pkgs.gnused
    #     pkgs.coreutils
    #   ]}
    #   # herdr's own version is part of the stamp: an upgrade can reset its plugin state.
    #   want="${pkgs.herdr} $(ls ${repo}/herdr/plugins) agent-usage@v0.5.11 annotate@1bc258353f0a7af0781493e1c1ffca09b71666bc"
    #   stamp="$HOME/.config/herdr/.dotfiles-plugins"
    #   if [ "$(cat "$stamp" 2>/dev/null)" = "$want" ]; then exit 0; fi
    #   # `herdr status server` exits 0 either way; its output says whether one runs.
    #   case "$(herdr status server 2>&1)" in
    #     *"not running"*)
    #       echo "dotfiles: skipped herdr-plugins: no herdr server is running. Start herdr, then switch again."
    #       exit 0
    #       ;;
    #   esac
    #   status=0
    #   for dir in ${repo}/herdr/plugins/*; do
    #     [ -f "$dir/herdr-plugin.toml" ] || continue
    #     herdr plugin unlink "$(basename "$dir")" >/dev/null 2>&1 || true
    #     herdr plugin link "$dir" >/dev/null || { echo "herdr plugin link $dir failed" >&2; status=1; }
    #   done
    #   # On-demand agent usage: keymap only, no sidebar rows and no toasts (keybindings live in herdr/config.toml).
    #   if herdr plugin install senna-lang/herdr-agent-usage --ref v0.5.11 --yes >/dev/null \
    #     && herdr plugin action invoke usagebar.setup >/dev/null; then
    #     if cfg="$(herdr plugin config-dir usagebar)/config.toml" && [ -f "$cfg" ]; then
    #       sed -i -E 's/^enabled[[:space:]]*=[[:space:]]*true/enabled = false/' "$cfg"
    #     else
    #       echo "agent-usage config not found; toasts may appear" >&2; status=1
    #     fi
    #   else
    #     echo "agent-usage install failed" >&2; status=1
    #   fi
    #   # Terminal and document annotation. It ships no setup action, so its keybindings are in herdr/config.toml.
    #   herdr plugin install plannotator/herdr-annotate --ref 1bc258353f0a7af0781493e1c1ffca09b71666bc --yes >/dev/null \
    #     || { echo "annotate install failed" >&2; status=1; }
    #   if [ "$status" = 0 ]; then echo "$want" > "$stamp"; fi
    #   exit $status
    # '';

    # Codex owns ~/.codex/config.toml and rewrites it as you work, so only the shareable keys are tracked and merged in.
    codexConfig = step "codex-config" ''
      ${binPath [ pkgs.python3 ]}
      DOTFILES=${repo} ${repo}/bin/codex-config apply >/dev/null
    '';

    # bat resolves a theme by name only from its cache.
    batCache = step "bat-cache" ''
      ${pkgs.bat}/bin/bat cache --build >/dev/null
    '';

    # Skipped with the full neovim setup.
    # # Neovim installs the plugins nvim/nvim-pack-lock.json pins on its first start; this makes that start happen during the switch instead of in front of you.
    # nvimPlugins = step "nvim-plugins" ''
    #   ${binPath [
    #     pkgs.git
    #     pkgs.neovim
    #     pkgs.tree-sitter
    #   ]}
    #   nvim --headless -c 'if v:errmsg != "" | cquit 1 | endif' -c 'qa'
    # '';

    # fish history lives at ~/.fish_history, linked from where fish looks for it.
    fishHistory = step "fish-history" ''
      data="$HOME/.local/share/fish"
      mkdir -p "$data"
      if [ -f "$HOME/fish_history" ] && [ ! -e "$HOME/.fish_history" ]; then mv "$HOME/fish_history" "$HOME/.fish_history"; fi
      if [ -f "$data/fish_history" ] && [ ! -L "$data/fish_history" ]; then mv "$data/fish_history" "$HOME/.fish_history"; fi
      if [ ! -e "$HOME/.fish_history" ]; then
        touch "$HOME/.fish_history"
        chmod 600 "$HOME/.fish_history"
      fi
      ln -snf "$HOME/.fish_history" "$data/fish_history"
    '';
  };
}
