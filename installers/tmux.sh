#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"

require_command git
require_command tmux

config_source="$DOTFILES_DIR/configs/tmux/tmux.conf"
config="$HOME/.tmux.conf"
tpm_dir="$HOME/.tmux/plugins/tpm"
socket_name="dotfiles-check-$$"

[[ -f "$config_source" ]] || fail "Repository tmux configuration is missing: $config_source"

if [[ "$DRY_RUN" != "1" ]]; then
  [[ -L "$config" ]] || fail "Linked tmux configuration is missing: $config"

  current_config_source="$(readlink "$config")"
  [[ "$current_config_source" == "$config_source" ]] ||
    fail "Unexpected tmux configuration link: $config -> $current_config_source"
fi

if [[ -d "$tpm_dir/.git" ]]; then
  success "TPM is already installed."
elif [[ -e "$tpm_dir" ]]; then
  fail "$tpm_dir exists but is not a TPM Git clone."
else
  run mkdir -p "$(dirname "$tpm_dir")"
  run git clone --depth=1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  print_command "$tpm_dir/bin/install_plugins"
  print_command tmux -L "$socket_name" -f "$config_source" new-session -d -s dotfiles-check
  print_command tmux -L "$socket_name" kill-server
  exit 0
fi

plugin_installer="$tpm_dir/bin/install_plugins"

[[ -x "$plugin_installer" ]] || fail "TPM plugin installer is missing: $plugin_installer"
"$plugin_installer"

cleanup_test_server() {
  tmux -L "$socket_name" kill-server >/dev/null 2>&1 || true
}

trap cleanup_test_server EXIT

tmux -L "$socket_name" -f "$config" new-session -d -s dotfiles-check
cleanup_test_server
trap - EXIT

success "tmux configuration and plugins are ready"
