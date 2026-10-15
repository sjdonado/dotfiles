# Verifying the macOS configuration

```sh
verify/macos/run.sh
```

The fast check for a change to the macOS half of the declaration. Nothing on this Mac changes.

- **With Nix on this Mac**, it builds `darwinConfigurations.<host>.system` from a filtered copy of the working tree, without activating it. A package that fails to build or two packages that provide the same file fail here.
- **Without Nix**, it evaluates the configuration inside a Linux container. That proves the configuration is well-formed and complete, but builds nothing; `verify/packages/run.sh` covers availability and collisions from there.

Either way, `verify.sh` then asserts on the evaluated configuration:

- every live link points at a file that exists in the working tree, and the links that matter most are declared;
- every setup step is declared, and the two launch agents run the scripts in this repository;
- the activation sets the Finder defaults and the login shell, and fish is listed for `/etc/shells`;
- nix-homebrew adopts `/opt/homebrew` with read-only, pinned taps, the switch never fetches taps, and every cask, Homebrew formula and App Store app in `openspec/changes/provision-with-nix/coverage.tsv` is declared;
- the key packages are in the home profile.

`HOST_CONFIG` and `USER_CONFIG` select another configuration (default: `Juans-MacBook-Pro`, `juan`).

## What it cannot cover

Anything that only happens on activation: Homebrew installing the casks, launchd loading the agents, `dscl` changing the login shell, Launch Services registering BrowserRouter. `verify/macos-vm/run.sh` switches a disposable macOS VM for real and asserts those; it has to pass before the first switch on a real Mac.
