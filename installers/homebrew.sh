#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"
require_macos

if has_command brew; then
  success "Homebrew is already installed: $(command -v brew)"
  exit 0
fi

if [[ "$DRY_RUN" == "1" ]]; then
  info "The official Homebrew installer would be downloaded and run."
  print_command /bin/bash /tmp/homebrew-install.sh
  exit 0
fi

temp_installer="$(mktemp)"
# defer cleanup
trap 'rm -f "$temp_installer"' EXIT

curl -fsSL \
  https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
  -o "$temp_installer"

/bin/bash "$temp_installer"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  fail "Homebrew installation finished, but brew could not be found."
fi

has_command brew || fail "Homebrew is unavailable after installation."
