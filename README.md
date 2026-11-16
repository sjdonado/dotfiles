# Dotfiles

Developer setup for macOS and Ubuntu, using Homebrew or apt with guarded installers. T3 Code owns development sessions. Nix is not required.

## Use

Clone into `~/.config/dotfiles`, then run:

```sh
./setup.sh
./sync.sh             # apply and check
./sync.sh --upgrade   # update, apply, and check
./sync.sh --check     # check without applying
```

Provisioning declarations, scripts, platform assets, and checks live in `setup/`. See `setup/README.md` for the layout and migration guidance.

On macOS, `setup/lib/hosts/macos.sh` declares accounts. Each account owns its own clone; only the primary account changes shared packages or machine state. Sync from the primary account applies each account's configuration from its own checkout.

Connect T3 providers, `gh`, and account-bound MCP servers separately in each account. Secrets and Hex settings stay local. Install App Store apps and choose default applications manually; open BrowserRouter once to accept its default-browser prompt.

## Agents

`AGENTS.md` is the instruction source of truth; `CLAUDE.md` is a symlink to it. Shared safeguards live in `agents/AGENTS.md`. Invoke `sjdonado-mode:` in T3 for development procedures; ordinary personal-agent tasks do not activate them. Provider binaries remain available for T3 integration.

See `agents/README.md` for mode usage, `agents/eval/checks.yaml` for manual harness checks, and `adrs/` for the reasoning behind major decisions.

## Verify

```sh
./setup/verify/macos.sh
./setup/verify/linux.sh --platform linux/arm64
./setup/verify/linux.sh --platform linux/amd64
```

macOS checks use temporary fixtures; Linux checks provision disposable containers. Details are in `setup/verify/README.md`.

## Happy hacking!

<img width="200" alt="Cat typing on a computer" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
