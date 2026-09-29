# Changelog

Notable changes to this project are documented in this file.

The project follows [Semantic Versioning](./VERSIONING.md). Versions marked **Unreleased** describe planned or in-progress work and may change before release.

## [2.0.0] - 2026-09-30

### Changed

- Replace the Stow-based workflow with a repository-owned, conflict-safe symlink installer and explicit link manifest.
- Add a modular macOS setup runner with ordered steps, selective execution, confirmation handling, and dry-run support.
- Define a clear ownership boundary: Homebrew manages system software and applications, while standalone mise manages language runtimes and development tools.
- Reorganize reusable configuration under `configs/` and managed scripts under `bin/`.
- Use `.bashrc` as shared Bash/Zsh configuration while keeping shell-specific setup separate.
- Initialize Git submodules as part of setup and make public bootstrap dependencies available over HTTPS.
- Replace TPM-managed tmux plugins with a dependency-free tmux configuration, accepting the documented feature tradeoffs.
- Add optional macOS preference configuration and comprehensive installation verification.
- Improve safety, idempotency, documentation, and testing for fresh-machine bootstrap.

### Breaking changes

- GNU Stow is no longer part of the intended setup workflow.
- Existing configuration locations and symlink targets may change.
- Tool ownership changes, including moving language runtimes to mise.
- Some tmux plugin features, including automatic session restoration, are removed from the default configuration.

## [1.0.0] - Initial implementation

- Added the initial collection of personal dotfiles and scripts.
- Documented a manual macOS bootstrap process.
- Used GNU Stow to create dotfile symlinks.
- Managed tools primarily through Homebrew and manual setup steps.
