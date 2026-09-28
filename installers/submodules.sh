#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"
require_command git

if [[ ! -f "$DOTFILES_DIR/.gitmodules" ]]; then
  info "No Git submodules are configured."
  exit 0
fi

# -C specifies the directory
run git -C "$DOTFILES_DIR" submodule sync --recursive
run git -C "$DOTFILES_DIR" submodule update --init --recursive
