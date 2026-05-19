# My Dotfiles

Setting up a new machine from scratch? See [macos.md](./macos.md) for the full Mac bootstrap checklist.

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
