# Dotfiles (v2.0.0)

A repeatable macOS (sorry, only macOS for now) bootstrap for my shell, dev tools, apps, runtimes and config files.

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
- **Runtime manager:** mise
- **Font:** Iosevka Term Nerd Font
- **System monitors:** btop, fastfetch

## Supported platform

Current version supports macOS on Apple Silicon and Intel Macs.

Run setup as your normal user, not with `sudo`.

## Quick Start

Install Apple Command Line Tools if necessary:

```bash
xcode-select --install
```

Clone the repository with its Neovim submodule:

```bash
git clone --recurse-submodules https://github.com/koutaroyumiba/dotfiles.git "$HOME/dotfiles"

cd "$HOME/dotfiles"
```

Preview the complete setup:

```bash
./setup --dry-run --yes
```

Run it:

```bash
./setup
```

Setup never overwrites conflicting dotfiles automatically. If a target already exists, the link installer reports every conflict and exits before creating anything.

## Usage

```bash
./setup --help
./setup --list
./setup --dry-run
./setup --only packages
./setup --only links,shell
./setup --skip macos
./setup --yes
```

Multiple values passed to `--only` or `--skip` are comma-separated.

The setup stages run in this order:

```text
preflight
homebrew
packages
submodules
links
shell
mise
tmux
macos
verify
```

## Manual Follow-up

Some settings remain manual:

- swap Caps Lock and Control if desired;
- disable Spotlight shortcuts that conflict with Raycast;
- sign in to applications;
- configure SSH keys and Git identity;

## Ownership

Just general conventions that I'm kinda figuring out while going through my dotfiles and configurations.

### Homebrew

Homebrew manages machine-level command-line tools and graphical applications declared in `Brewfile`.

Examples include:

- Git
- Neovim
- tmux
- Wezterm
- Aerospace
- Raycast
- Obsidian
- Iosevka Term Nerd Font (best font btw)

### Mise

mise is installed independently through `https://mise.run`, not Homebrew (cuz the docs told me to).

mise manages:

- Node LTS
- `pnpm`

`npm` is included with Node. The mise installer uses `npm` to install Pi globally.

Global defaults are declared in `configs/mise/config.toml`

### Configuration Links

`installers/links.sh` creates explicit absolute symlinks from the repository into the home directory. GNU stow is not required.

## Safety

The bootstrap system:

- supports dry runs;
- validates all links before creating any;
- does not overwrite files or directories;
- does not manage secrets and auth states;
- prompts before changing the login shell or macOS preferences;
