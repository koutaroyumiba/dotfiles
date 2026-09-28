#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"

require_command git
require_command zsh

oh_my_zsh_dir="$HOME/.oh-my-zsh"

if [[ -d "$oh_my_zsh_dir/.git" ]]; then
  success "Oh My Zsh is already installed."
elif [[ -e "$oh_my_zsh_dir" ]]; then
  fail "$oh_my_zsh_dir exists but is not an Oh My Zsh Git clone."
else
  # we clone instead of using their installer because we don't want
  # the installer affecting the other config files (like zshrc)
  run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$oh_my_zsh_dir"
fi

zsh_path="$(command -v zsh)"

if [[ "${SHELL:-}" == "$zsh_path" ]]; then
  success "Zsh is already the login shell."
elif confirm "Set $zsh_path as the login shell?"; then
  run chsh -s "$zsh_path"
  warn "The new login shell takes effect in a new terminal session."
else
  warn "Login shell was not changed."
fi

if [[ ! -f "$HOME/.bash_aliases_local" ]]; then
  info "Optional local aliases example: $DOTFILES_DIR/examples/bash_aliases_local.example"
fi
