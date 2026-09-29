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

Setup asks for confirmation before making changes. Pass `--yes` to bypass confirmation prompts.

Setup never overwrites conflicting dotfiles automatically. If a target already exists, the link installer reports every conflict and exits before creating anything.

### Initial versus later runs

Use `./setup` from the repository root for the initial bootstrap. At that point, `~/bin` and the shell `PATH` may not be configured yet.

The initial setup links this repository's `bin/` directory to `~/bin`. After opening a new terminal, run `setup` from any directory:

```bash
setup --help
setup --only packages
```

## Usage

```bash
setup --help
setup --list
setup --dry-run
setup --only packages
setup --only links,shell
setup --skip macos
setup --yes
```

Informational and dry-run commands do not prompt for confirmation. Multiple values passed to `--only` or `--skip` are comma-separated, and unknown step names are rejected.

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
- install helium (browser)
- install obsidian (note taking)
- install raycast (better spotlight)

## Ownership

Just general conventions that I'm kinda figuring out while going through my dotfiles and configurations.

### Homebrew

Homebrew manages machine-level command-line tools and graphical applications declared in `Brewfile`.

Examples include:

- Neovim, Git, tmux, ripgrep, fd, and fzf.
- Compilers and native libraries such as OpenSSL and SQLite.
- Services such as PostgreSQL.
- Iosevka Term Nerd Font (best font btw)

### Mise

mise is installed independently through `https://mise.run`, not Homebrew (cuz the docs told me to).

`mise` owns language runtimes and development tools whose versions may differ by project.

Examples include:

- Node.js, Go, Lua and Zig.
- Terraform.
- Bun and Deno.
- pnpm and similar language-ecosystem package managers.

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

## Version History

This repository uses [Semantic Versioning](./VERSIONING.md).

### v2.0.0 — Current release

A redesigned macOS bootstrap system with a modular setup runner, conflict-safe symlink management without GNU Stow, clearer Homebrew and mise ownership, reorganized configuration, and improved verification and documentation.

See [CHANGELOG.md](./CHANGELOG.md) for full release details.

### v1.0.0 — Initial implementation

The initial collection of personal dotfiles and scripts, using a manual macOS setup process and GNU Stow for symlink management.
