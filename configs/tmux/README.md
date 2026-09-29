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
prefix + f              // open tms project/session picker
Ctrl-h/j/k/l            // navigate between Neovim splits and tmux panes
```

## tms

`tms` fuzzy-finds project directories and existing tmux sessions. It runs in a
popup from `prefix + f`, and can also be invoked directly from a shell:

```bash
tms                 # open the picker
tms .               # open the current directory
tms ~/dev/project   # open a specific project
tms --help
```

Project roots and search depths are configured at the top of `bin/tms`:

```bash
readonly TMS_CONFIG=(
  "$HOME/dotfiles:0"  # include only the root
  "$HOME/workspace:1" # include the root and direct children
  "$HOME/dev:2"       # include the root and two child levels
)
```

`tms` switches clients when invoked inside tmux and attaches when invoked from
a normal shell. If two projects have the same basename, it adds a short stable
path hash to prevent their sessions from colliding.

## Updates

Setup installs only missing plugins. It does not update or remove existing plugins automatically.

Run `prefix + U` to review and update plugins interactively.
