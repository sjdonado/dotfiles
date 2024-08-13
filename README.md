> Blazyinly fast Development Setup 🚀

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

# Shell
chsh -s /bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
brew install fzf

ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
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
