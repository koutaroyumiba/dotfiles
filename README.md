# My Dotfiles

Add the following to `~/.bashrc` for aliases
```bash
if [ -f ~/dotfiles/.bash_aliases ]; then
	. ~/dotfiles/.bash_aliases
fi
```

Create a symlink for each dotfile

Recommended to use stow:

```shell
brew install stow # on mac

stow [package]
```

# TMUX

## Installation

Make sure to install the following dependencies:
- ![tmux](https://github.com/tmux/tmux/wiki/Installing)
- ![tpm](https://github.com/tmux-plugins/tpm)

Clone the repository to your `$XDG_CONFIG_HOME/tmux/` directory:
```bash
git clone git@github.com:koutaroyumiba/tmux.git
```

To install the plugins, run `prefix + I` (default: `Ctrl + b, I`).
