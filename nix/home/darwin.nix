# macOS only, for the user: the Mac's command-line tools, its links, launch agents and setup steps. System state is in nix/darwin/.
{
  lib,
  pkgs,
  inputs,
  dotfiles,
  ...
}:
let
  inherit (dotfiles) repo live step;

  # Some commands only, under the names Homebrew gave them: GNU tools that would otherwise shadow the macOS ones (`sed`, `awk`, the inetutils set) on PATH.
  only =
    name: pkg: links:
    pkgs.runCommand name { } (
      "mkdir -p $out/bin\n"
      + lib.concatMapStrings (l: "ln -s ${pkg}/bin/${l.from} $out/bin/${l.to}\n") links
    );

  # Versions Homebrew kept off PATH (keg-only), because they share command names with the default version. Each is linked at ~/.local/opt/<name> with what the Homebrew keg had: binaries, libraries and headers.
  keg =
    name: paths:
    pkgs.symlinkJoin {
      name = "keg-${name}";
      inherit paths;
    };
  kegs = {
    jdk11 = pkgs.jdk11;
    jdk17 = pkgs.jdk17;
    # Homebrew's llvm keg carries clang, lld and lldb too.
    llvm = keg "llvm" (
      with pkgs.llvmPackages;
      [
        llvm.out
        llvm.lib
        llvm.dev
        clang-unwrapped.out
        clang-unwrapped.lib
        clang-unwrapped.dev
        lld
        lldb
      ]
    );
    openssl-4 = keg "openssl-4" (
      with pkgs.openssl_4_0;
      [
        bin
        out
        dev
      ]
    );
    zig-0_15 = pkgs.zig_0_15;
  };
in
{
  home.packages = with pkgs; [
    act
    awscli2
    blueutil
    bombardier
    caddy
    cacert
    cairo
    chawan
    cloudflared
    cmake
    cocoapods
    coreutils-prefixed # g-prefixed, as Homebrew's coreutils
    crystal
    curlie
    delta
    difftastic
    duckdb
    duti
    flyctl
    gcx
    gh
    ghostscript
    giflib
    git-bug
    git-lfs
    gnutls
    go
    go-tools # staticcheck
    golangci-lint
    grpcurl
    harfbuzz
    htop
    idb-companion
    imagemagick
    jdk # the default java; jdk11 and jdk17 are kegs below
    jsoncpp
    libcoap
    libjpeg
    libpng
    libpq
    librsvg
    llama-cpp
    lua
    luarocks
    mackup
    mailpit
    mkcert
    nmap
    nss
    openssl
    ory
    p7zip
    pandoc
    pango
    pi-coding-agent
    pipx
    pixman
    pkgconf
    poppler-utils
    pv
    python312
    qpdf
    rbenv
    rustup
    scc
    scrcpy
    sqlmap
    stripe-cli
    supabase-cli
    swaks
    tor
    tree
    watchman
    whisper-cpp
    wrangler
    xcodegen
    xq-xml
    zig
    # Formerly `go install`ed at @latest; now pinned like everything else.
    air
    bootdev-cli
    goose
    (only "gawk" gawk [
      {
        from = "gawk";
        to = "gawk";
      }
    ])
    (only "gsed" gnused [
      {
        from = "sed";
        to = "gsed";
      }
    ])
    (only "telnet" inetutils [
      {
        from = "telnet";
        to = "telnet";
      }
    ])
  ];

  home.file = {
    # OrbStack supplies the docker client and links its own buildx and compose into ~/.docker/cli-plugins.
    ".docker/config.json" = live "docker/config.json";
    ".ssh/config" = live ".ssh/config";
    ".hushlogin".text = "";
  }
  // lib.mapAttrs' (name: pkg: lib.nameValuePair ".local/opt/${name}" { source = pkg; }) kegs;

  # The routing rules are tracked here; the app reads them from this path.
  xdg.configFile."browser-router/config.json" = live "macos/browser-router.json";

  # launchd does not expand $HOME, so the scripts are named by their full path; Login Items shows each by its script name.
  launchd.agents = {
    KeyRemapping = {
      enable = true;
      config = {
        ProgramArguments = [ "${repo}/macos/caps-to-control.sh" ];
        RunAtLoad = true;
      };
    };
    TMExcludeDev = {
      enable = true;
      config = {
        ProgramArguments = [ "${repo}/macos/tm-exclude-dev.sh" ];
        StartCalendarInterval = [
          {
            Hour = 12;
            Minute = 0;
          }
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/tm-exclude-dev.log";
        StandardErrorPath = "/tmp/tm-exclude-dev.log";
      };
    };
  };

  home.activation = {
    # PSS, the Pi harness scheme (macOS only, where pi is), from the pinned input: copied out of the store (bun install writes node_modules beside it) and linked into ~/.local/bin. A stamp skips the copy while the pin is unchanged.
    pss = step "pss" ''
      export PATH=${lib.makeBinPath [ pkgs.bun pkgs.coreutils ]}:$PATH
      dir="$HOME/.local/share/pss"
      if [ "$(cat "$dir/.source" 2>/dev/null)" != "${inputs.pss}" ]; then
        rm -rf "$dir"
        mkdir -p "$(dirname "$dir")"
        cp -R ${inputs.pss} "$dir"
        chmod -R u+w "$dir"
        bun install --ignore-scripts --no-save --cwd "$dir" >/dev/null
        echo "${inputs.pss}" > "$dir/.source"
      fi
      mkdir -p "$HOME/.local/bin"
      ln -snf "$dir/bin/pss" "$HOME/.local/bin/pss"
    '';

    # The two agents macos.sh rendered under com.local.* are replaced by the ones above.
    retireOldAgents = step "retire-old-agents" ''
      for label in com.local.KeyRemapping com.local.TMExcludeDev; do
        plist="$HOME/Library/LaunchAgents/$label.plist"
        [ -e "$plist" ] || continue
        /bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$plist" 2>/dev/null || true
        rm -f "$plist"
      done
    '';

    # Copied, not linked: macOS does not load keyboard layouts through symlinks.
    keyboardLayouts = step "keyboard-layouts" ''
      mkdir -p "$HOME/Library/Keyboard Layouts"
      cp -Rp ${repo}/macos/ukelele/* "$HOME/Library/Keyboard Layouts/"
    '';

    # The browser-router formula stops at the bundle inside the Homebrew prefix. Launch Services only sends links to a registered bundle, so it is copied to ~/Applications and registered there. Making it the default browser is a system prompt: open the app once.
    browserRouter = step "browser-router" ''
      app=/opt/homebrew/opt/browser-router/BrowserRouter.app
      dst="$HOME/Applications/BrowserRouter.app"
      if [ ! -d "$app" ]; then
        echo "dotfiles: skipped browser-router: $app is missing (Homebrew installs it during the switch)"
        exit 0
      fi
      if ! /usr/bin/cmp -s "$app/Contents/MacOS/BrowserRouter" "$dst/Contents/MacOS/BrowserRouter"; then
        mkdir -p "$HOME/Applications"
        rm -rf "$dst"
        cp -R "$app" "$HOME/Applications/"
      fi
      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$dst"
    '';

    defaultApps = step "default-apps" ''
      ${pkgs.duti}/bin/duti ${repo}/macos/default-apps.duti
    '';

    # Not nix-darwin's CustomUserPreferences: Safari's domain fails without Full Disk Access, and that failure would stop the whole activation. The script reports each failure and continues.
    appShortcuts = step "app-shortcuts" ''
      ${repo}/macos/app-shortcuts.sh
    '';

    # Tools that source the repository's .env expect the file to exist.
    envFile = step "env-file" ''
      [ -e ${repo}/.env ] || touch ${repo}/.env
    '';
  };
}
