# Changelog

Notable changes to this project are documented in this file.

The project follows [Semantic Versioning](./VERSIONING.md). Versions marked **Unreleased** are complete release candidates that have not yet been tagged.

## [2.0.0] - Unreleased

**Status:** Implementation complete; pending final release and Git tag.

### Added

- Added a modular macOS setup runner with ordered installers, selective execution, confirmation handling, and dry-run support.
- Added a repository-owned, conflict-safe symlink installer with an explicit macOS link manifest.
- Added standalone mise management for Node LTS and pnpm.
- Added installation of Pi through npm provided by mise-managed Node.
- Added automatic Git submodule initialization.
- Added shell setup for Bash, Zsh, Oh My Zsh, portable aliases, and unmanaged machine-local aliases.
- Added TPM and tmux plugin installation with isolated configuration validation.
- Added optional Dock preference configuration with explicit confirmation.
- Added comprehensive verification for commands, runtimes, links, submodules, shell syntax, tmux plugins, tmux configuration, and macOS preferences.

### Changed

- Reorganized reusable configuration beneath `configs/` and managed executables beneath `bin/`.
- Moved the Neovim submodule to `configs/nvim` and changed its public URL to HTTPS.
- Linked the complete repository-owned `bin/` directory to `~/bin`.
- Made `.bashrc` shared by Bash and Zsh while keeping login and shell-specific setup separate.
- Assigned machine-level tools and applications to Homebrew and language runtimes to standalone mise.
- Replaced Volta-managed Node, npm, pnpm, and Pi with mise-managed Node and npm-installed Pi.
- Retained TPM for `vim-tmux-navigator`, `tmux-resurrect`, `tmux-continuum`, `tmux-sensible`, and `tmux-yank`; setup now installs missing plugins non-interactively.
- Kept `configs/claude` as archived reference material rather than linking it into `~/.claude`.
- Updated the active Pi configuration paths to `configs/pi`.

### Safety

- Link validation checks the complete manifest before creating anything.
- Existing files, directories, and unexpected symlinks are never overwritten automatically.
- Parent-directory conflicts are detected before link creation.
- Dry runs print commands without mutating the machine.
- Local aliases, authentication, sessions, caches, and application runtime state remain unmanaged.
- macOS preferences and login-shell changes require confirmation.

### Breaking changes

- GNU Stow is no longer part of the setup workflow.
- Managed configuration locations and symlink targets have changed.
- `~/bin` is now owned as a single repository-linked directory.
- Language-runtime ownership moves from Volta to standalone mise.
- Pi moves from a Volta-managed installation to npm under mise-managed Node.
- Shell startup files are now repository-managed links, with machine-specific aliases moved to `~/.bash_aliases_local`.

## [1.0.0] - Initial implementation

- Added the initial collection of personal dotfiles and scripts.
- Documented a manual macOS bootstrap process.
- Used GNU Stow to create dotfile symlinks.
- Managed tools primarily through Homebrew and manual setup steps.
