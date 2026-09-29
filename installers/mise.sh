#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"

require_command curl

install_path="$HOME/.local/bin/mise"
config_source="$DOTFILES_DIR/configs/mise/config.toml"
config="$HOME/.config/mise/config.toml"
pi_package="@earendil-works/pi-coding-agent"

[[ -f "$config_source" ]] || fail "Repository mise configuration is missing: $config_source"

if [[ "$DRY_RUN" != "1" ]]; then
  [[ -L "$config" ]] || fail "Linked mise configuration is missing: $config"

  current_config_source="$(readlink "$config")"
  [[ "$current_config_source" == "$config_source" ]] ||
    fail "Unexpected mise configuration link: $config -> $current_config_source"
fi

if [[ -x "$install_path" ]]; then
  mise_command="$install_path"
elif has_command mise; then
  fail "mise exists at $(command -v mise), but the expected standalone installation is $install_path"
elif [[ "$DRY_RUN" == "1" ]]; then
  info "The official mise installer would be downloaded and run."
  print_command curl -fsSL https://mise.run -o /tmp/mise-install.sh
  print_command env "MISE_INSTALL_PATH=$install_path" /bin/sh /tmp/mise-install/sh
  mise_command="$install_path"
else
  temp_installer="$(mktemp)"
  trap 'rm -f "$temp_installer"' EXIT

  mkdir -p "$(dirname "$install_path")"

  curl -fsSL https://mise.run -o "$temp_installer"
  MISE_INSTALL_PATH="$install_path" /bin/sh "$temp_installer"

  [[ -x "$install_path" ]] || fail "mise installation finished, but the exe was not found: $install_path"
  mise_command="$install_path"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  print_command "$mise_command" install
  print_command "$mise_command" exec -- npm install -g --ignore-scripts "$pi_package"
  exit 0
fi

"$mise_command" install
"$mise_command" exec -- npm install -g --ignore-scripts "$pi_package"

"$mise_command" exec -- node --version
"$mise_command" exec -- npm --version
"$mise_command" exec -- pnpm --version
"$mise_command" exec -- pi --version
"$mise_command" exec -- go version
"$mise_command" exec -- lua -v
"$mise_command" exec -- zig version
