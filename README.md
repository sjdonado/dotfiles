> Bye bye vscode 👋🏽

<img width="1400" alt="nvim screenshot" src="https://user-images.githubusercontent.com/27580836/235738484-d57b9e9d-8d7e-42e1-aa05-a5865a70d7ec.png">

# Setup
1. Clone into `~/.config/dotfiles`
2. Run `./bootstrap.sh`
3. Run `./shell/fish/setup.sh`
4. Run `./bin/osx.sh`

## Config nvim plugins
```vim
:PackerSync
:MasonToolsInstall
```

## Tor proxy
1. Enable tor service `brew services start tor`
2. In Firefox, go to `Network Settings > Manual proxy configuration > SOCKS Host > SOCKS v5` and set `localhost:9050`
3. Toggle on `Proxy DNS when using SOCKS v5`
4. Install [https://duckduckgogg42xjoc72x3sjasowoarfbgcmvfimaftt6twagswzczad.onion](https://addons.mozilla.org/en-US/firefox/addon/duckduckgo-onion)

### Happy Hacking!
<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
