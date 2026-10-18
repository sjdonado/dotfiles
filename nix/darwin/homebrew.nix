# Homebrew, driven by the switch and never by hand. It supplies what Nix packages cannot: GUI apps (casks, which install real bundles into /Applications that Launch Services, Spotlight and Raycast index), the three formulas nixpkgs lacks, and Mac App Store apps.
#
# nix-homebrew installs Homebrew at the version flake.lock pins and adopts the existing /opt/homebrew. Taps are flake inputs and read-only, so a tap, and with it every cask and formula version, moves only when flake.lock does.
{
  config,
  inputs,
  user,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "sjdonado/homebrew-tap" = inputs.homebrew-sjdonado;
      "driceroland/homebrew-tap" = inputs.homebrew-driceroland;
    };
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      # The taps are pinned inputs; fetching newer ones here would defeat the pin.
      autoUpdate = false;
      # Moves installed items to the versions the pinned taps name.
      upgrade = true;
      # Removes formulas and casks this file does not list, keeping their app data; "zap" would also delete that.
      cleanup = "uninstall";
    };

    brews = [
      # BrowserRouter, the default browser. The tap builds it from source with swiftc; nix/home/darwin.nix registers the bundle.
      "sjdonado/tap/browser-router"
      "cliclick"
      # gcloud-cli's dependencies. Cleanup keeps the dependencies of listed formulas but not of casks, so without these every switch tries to uninstall them and Homebrew refuses.
      "ca-certificates"
      "mpdecimal"
      "openssl@3"
      "readline"
      "sqlite"
      "xz"
    ];

    casks = [
      "1password"
      "1password-cli"
      "android-commandlinetools"
      "annotate"
      "betterdisplay"
      "cap"
      "gcloud-cli"
      "google-chrome"
      "granola"
      "helium-browser"
      "icon-composer"
      "imageoptim"
      "linear"
      # Local meeting transcription and dictation.
      "muesli"
      "ngrok"
      "nordvpn"
      "orbstack"
      "raycast"
      "rockxy"
      "slack"
      "tablepro"
      "tailscale-app"
      "t3-code"
      "telegram-desktop"
      "whatsapp"
      "yaak"
      "zed"
    ];

    # App Store apps are installed by hand (owner's decision, 2026-10-17): mas needs an App Store sign-in and installs Xcode-sized apps during every first switch. Uncomment to declare them again; Homebrew never uninstalls these, so removing one from this list is a manual step too.
    masApps = { };
    # masApps = {
    #   "1Password for Safari" = 1569813296;
    #   "DaisyDisk" = 411643860;
    #   "Developer" = 640199958;
    #   "GarageBand" = 682658836;
    #   "GoodLinks" = 1474335294;
    #   "iMovie" = 408981434;
    #   "Keynote" = 361285480;
    #   "Numbers" = 361304891;
    #   "Pages" = 361309726;
    #   "Raycast Companion" = 6738274497;
    #   "TestFlight" = 899247664;
    #   "uBlock Origin Lite" = 6745342698;
    #   "Xcode" = 497799835;
    # };
  };
}
