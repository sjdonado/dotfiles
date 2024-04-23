> Blazyinly fast Development Setup 🚀

<img width="1756" alt="Screenshot 2024-04-23 at 10 16 41" src="https://github.com/sjdonado/dotfiles/assets/27580836/8c583289-8b35-4a92-9687-d57d1ec770fd">

## Getting started

1. Clone this repo into `~/.config/dotfiles`

### Terminal + multiplexer + shell

```fish
# Setup alacritty
brew install alacritty
ln -s "~/.config/dotfiles/alacritty/alacritty.toml" ~/.config/alacritty.toml

# Tmux config
brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Fish shell
brew install fish
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
ln -sf "~/.config/dotfiles/fish/config.fish" ~/.config/fish/config.fish
```

### Editor

- Default config
```fish
brew install nvim lua
ln -s "~/.config/dotfiles/nvim" ~/.config/nvim
```
- Open `nvim .`
- Check updates
```vim
:Lazy
:Mason
```

### Happy Hacking!
<img width="200" alt="image" src="https://media.tenor.com/y2JXkY1pXkwAAAAM/cat-computer.gif">
