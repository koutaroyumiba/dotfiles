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
