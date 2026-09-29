#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"

require_macos
require_command defaults

if ! confirm "Apply the tracked macOS preferences?"; then
  warn "macOS preference changes skipped."
  exit 0
fi

run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock expose-group-apps -bool true

if [[ "$DRY_RUN" == "1" ]]; then
  print_command killall Dock
else
  killall Dock >/dev/null 2>&1 || true
fi
