# New Mac Setup

A checklist for setting up a new personal Mac with my preferred configuration.

## Overview

The target setup at a glance:

- **Browser:** Helium
- **Launcher:** Raycast
- **Window manager:** Aerospace
- **Terminal:** WezTerm
- **Shell:** Zsh (with Oh My Zsh)
- **Multiplexer:** tmux
- **Editor:** Neovim
- **Package manager:** Homebrew
- **Node toolchain:** Volta (manages `node`, `npm`, `pnpm`)
- **Dotfiles manager:** GNU Stow
- **Font:** Iosevka Term Nerd Font
- **System monitors:** btop, fastfetch

## 1. System Preferences

Adjust the following from **System Settings**:

- **Keyboard → Keyboard Shortcuts → Modifier Keys** — swap Caps Lock and Control.
- **Keyboard → Keyboard Shortcuts → Spotlight** — disable Spotlight shortcuts (freed up for Raycast).
- **Desktop & Dock** — enable *Automatically hide and show the Dock* and *Group windows by application*.

## 2. Applications (manual install)

These are installed outside of Homebrew:

- [Homebrew](https://brew.sh)
- [Helium browser](https://helium.computer)
- [Raycast](https://www.raycast.com)
- [Aerospace](https://github.com/nikitabobko/AeroSpace) (also available via the Brewfile)
- [Obsidian](https://obsidian.md)
- OpenCode

## 3. Homebrew packages

From the root of this repository, install everything declared in the `Brewfile`:

```sh
brew bundle
```

This installs the command-line tools (`git`, `neovim`, `stow`, `tmux`, `fzf`, `ripgrep`, `fd`, `coreutils`, `btop`, `fastfetch`, etc.) along with WezTerm, Aerospace, and the Iosevka Nerd Font cask.

## 4. Node toolchain

Install [Volta](https://volta.sh) to manage the Node toolchain:

```sh
curl https://get.volta.sh | bash
```

Then install Node, npm, and pnpm:

```sh
volta install node
volta install npm
volta install pnpm
```

## 5. Shell

Install [Oh My Zsh](https://ohmyz.sh), then append the following to `~/.zshrc` so shared aliases and environment settings from `.bashrc` are picked up:

```sh
# Source .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi
```

## 6. Dotfiles

Clone this repository to `~/dotfiles` and symlink the configurations with `stow` (see the [README](./README.md) for details).

## 7. Application configuration

- **Helium** — *Settings → Appearance → Browser Layout* → Vertical.
- **Neovim** — the Neovim configuration has external dependencies (language servers, tree-sitter parsers, etc.); install them as prompted on first launch.
