# tmux configuration

This directory contains my tmux configuration :D

## Ownership

- Homebrew installs the `tmux` executable.
- This repository manages `~/.tmux.conf`.
- `installers/tmux.sh` installs TPM and missing plugins.
- TPM stores plugins under `~/.tmux/plugins`.

The setup process does not update or remove existing plugins automatically.

## Installation

Run:

```bash
./setup --only links,tmux

# if links already exist
./setup --only tmux
```

To install the plugins, run `prefix + I` (default: `Ctrl + b, I`, config: `Ctrl + a, I`).
To install missing plugins manually, run `Ctrl-a, I`.

## Plugins

### tmux-sensible

Provides conservative default tmux settings - history, terminal behaviour and general tmux usability

### vim-tmux-navigator

Provides seamless navigation between Neovim splits and tmux panes.

### tmux-yank

Adds clipboard integration for copy mode

### tmux-resurrect

Saves and restores tmux sessions, windows, panes, layouts, and working directories.

### tmux-continuum

Periodically saves tmux state and restores it when a new tmux server starts.

## Useful Bindings

```
prefix + I              // install missing plugins
prefix + U              // update plugins interactively
prefix + Ctrl-s         // save tmux state with resurrect
prefix + Ctrl-r         // restore tmux state with resurrect
prefix + r              // reload ~/.tmux.conf
prefix + v              // split horizontally
prefix + h              // split vertically
prefix + m              // toggle pane zoom
prefix + f              // open tmux-sessionizer
Ctrl-h/j/k/l            // navigate between Neovim splits and tmux panes
```

## Updates

Setup installs only missing plugins. It does not update or remove existing plugins automatically.

Run `prefix + U` to review and update plugins interactively.
