#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"
require_macos

if has_command brew; then
  brew_command="$(command -v brew)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  brew_command="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
  brew_command="/usr/local/bin/brew"
elif [[ "$DRY_RUN" == "1" && "$(uname -m)" == "arm64" ]]; then
  brew_command="/opt/homebrew/bin/brew"
elif [[ "$DRY_RUN" == "1" && "$(uname -m)" == "x86_64" ]]; then
  brew_command="/usr/local/bin/brew"
else
  fail "Required command not found: brew"
fi

brewfile="$DOTFILES_DIR/Brewfile"
[[ -f "$brewfile" ]] || fail "Brewfile not found: $brewfile"

run "$brew_command" bundle --file="$brewfile"
