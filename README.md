> Bye bye vscode 👋🏽

<img width="1470" alt="image" src="https://github.com/sjdonado/dotfiles/assets/27580836/0a2abe2c-5f06-4ab8-9536-9b2c6d275db0">

# Setup
1. Clone into `~/.config/dotfiles`
1. Run `./bootstrap.sh`
1. Run `./bin/osx.sh`
1. Run `mackup restore`

## Config Neovim Plugins
```vim
:PackerSync
:MasonToolsInstall
```

## Tor Proxy
1. Enable tor service `brew services start tor`
2. In Firefox, go to `Network Settings > Manual proxy configuration > SOCKS Host > SOCKS v5` and set `localhost:9050`
3. Toggle on `Proxy DNS when using SOCKS v5`
4. Install [https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion](https://addons.mozilla.org/en-US/firefox/addon/duckduckgo-onion)

### Happy Hacking!
<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
