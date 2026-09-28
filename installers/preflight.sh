#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"
require_macos

[[ "$EUID" -ne 0 ]] || fail "Run setup as your normal user, not with sudo."

architecture="$(uname -m)"
case "$architecture" in
  arm64|x86_64)
    info "Architecture: $architecture"
    ;;
  *)
    fail "Unsupported Mac architecture: $architecture"
    ;;
esac

run mkdir -p "$HOME/.config"
run mkdir -p "$HOME/.local/bin"
run mkdir -p "$HOME/workspace"

if ! xcode-select -p >/dev/null 2>&1; then
  if [[ "$DRY_RUN" == "1" ]]; then
    print_command xcode-select --install
  else
    warn "Apple Command Line Tools are not installed."
    xcode-select --install || true
    fail "Finish the Command Line Tools installation, then run ./setup again."
  fi
fi

success "Preflight checks passed."
