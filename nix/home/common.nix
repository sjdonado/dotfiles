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
  # One live link per file of a repository directory, for directories where tools keep their own files beside ours (~/.local/bin, themes).
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
in
{
  # Shared with nix/home/darwin.nix.
  _module.args.dotfiles = { inherit repo live step; };

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Shell, editor and the tools the configs call.
    git
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

    # Agent harnesses and their tools. Claude Code and Codex are not packages: the agentClis step installs them.
    (callPackage ../pkgs/opencode.nix { }) # v2; nixpkgs still has v1
    openspec

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
  }
  // liveEach "bin" ".local/bin";

  xdg.configFile = {
    # The directory, not its files: init.lua resolves nvim-pack-lock.json relative to the config directory it loaded from. Skipped with the full neovim setup.
    # "nvim" = live "nvim";
    "worktrunk/config.toml" = live "worktrunk/config.toml";
    "zed/settings.json" = live "zed/settings.json";
    "zed/keymap.json" = live "zed/keymap.json";
    "opencode/opencode.json" = live "opencode/opencode.json";
    "opencode/cli.json" = live "opencode/cli.json";
    "opencode/AGENTS.md" = live "opencode/AGENTS.md";
    # The file, not plugins/: other tools write their own plugins beside this one.
    "opencode/plugins/no-foreground-wait.ts" = live "opencode/plugins/no-foreground-wait.ts";
  }
  // liveEach "bat/themes" "bat/themes";

  home.activation = {
    # Claude Code and Codex from their own installers, not Nix: T3 Code's update button runs `claude update` or `codex update`, which only work on these installs, and GUI apps look for them in ~/.local/bin, where both installers link them. The switch installs whichever is missing and leaves the version to the tool. ~/.local/bin is on PATH first, so neither installer edits a shell profile; the Nix tools after the system's fill what a bare Linux box lacks.
    agentClis = step "agent-clis" ''
      export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${lib.makeBinPath (with pkgs; [ curl coreutils gnutar gzip gawk gnused gnugrep findutils jq zstd bash ])}"
      case "$(readlink -f "$HOME/.local/bin/claude" 2>/dev/null || true)" in
        "$HOME"/.local/share/claude/*) ;;
        *) echo "dotfiles: installing Claude Code"; curl -fsSL https://claude.ai/install.sh | bash >/dev/null ;;
      esac
      case "$(readlink -f "$HOME/.local/bin/codex" 2>/dev/null || true)" in
        "$HOME"/.codex/packages/standalone/*) ;;
        *) echo "dotfiles: installing Codex"; curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh >/dev/null ;;
      esac
    '';

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

  };
}
