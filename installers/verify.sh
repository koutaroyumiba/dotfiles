#!/usr/bin/env bash
set -uo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"
source "$DOTFILES_DIR/profiles/macos.sh"

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  info "Verification is skipped during dry runs..."
  exit 0
fi

failures=0

commands=(
  brew
  git
  nvim
  tmux
  wezterm
  fzf
  rg
  fd
)

# command verification
for command_name in "${commands[@]}"; do
  if has_command "$command_name"; then
    success "Found command: $command_name"
  else
    warn "Missing command: $command_name"
    ((failures += 1))
  fi
done

# mise verification
mise_command="$HOME/.local/bin/mise"

if [[ -x "$mise_command" ]]; then
  success "Found standalone mise: $mise_command"
else
  warn "Standalone mise is missing: $mise_command"
  ((failures += 1))
fi

if [[ -x "$mise_command" ]]; then
  for runtime_command in node npm pnpm pi; do
    if "$mise_command" exec -- "$runtime_command" --version >/dev/null 2>&1; then
      success "Found mise-managed command: $runtime_command"
    else
      warn "Missing mise-managed command: $runtime_command"
      ((failures += 1))
    fi
  done

  for runtime_command in go zig; do
    if "$mise_command" exec -- "$runtime_command" version >/dev/null 2>&1; then
      success "Found mise-managed command: $runtime_command"
    else
      warn "Missing mise-managed command: $runtime_command"
      ((failures += 1))
    fi
  done

  if "$mise_command" exec -- lua -v >/dev/null 2>&1; then
    success "Found mise-managed command: lua"
  else
    warn "Missing mise-managed command: lua"
    ((failures += 1))
  fi
fi

# symlink verification
for mapping in "${DOTFILE_LINKS[@]}"; do
  relative_source="${mapping%%|*}"
  target="${mapping#*|}"
  expected="$DOTFILES_DIR/$relative_source"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$expected" ]]; then
    success "Correct link: $target"
  else
    warn "Missing or incorrect link: $target"
    ((failures += 1))
  fi
done

# submodule verification
if [[ -f "$DOTFILES_DIR/.gitmodules" ]]; then
  submodule_status="$(git -C "$DOTFILES_DIR" submodule status --recursive 2>&1)"
  submodule_command_status=$?

  if ((submodule_command_status != 0)); then
    warn "Unable to inspect Git submodules: $submodule_status"
    ((failures += 1))
  elif grep -qE '^[+-U]' <<<"$submodule_status"; then
    warn "At least one Git submodule is uninitialized or differs from its recorded commit."
    ((failures += 1))
  else
    success "Git submodules match their recorded commits"
  fi
fi

if bash -n "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_aliases"; then
  success "Bash configurations parses successfully."
else
  warn "Bash configuration contains a syntax error."
  ((failures += 1))
fi

if zsh -n "$HOME/.bashrc" "$HOME/.bash_aliases" "$HOME/.zprofile" "$HOME/.zshrc"; then
  success "Shared and Zsh configuration parses successfully."
else
  warn "Shared or Zsh configuration contains a syntax error."
  ((failures += 1))
fi

# tmux verification
plugins=(
  tpm
  tmux-sensible
  vim-tmux-navigator
  tmux-yank
  tmux-resurrect
  tmux-continuum
)

for plugin in "${plugins[@]}"; do
  plugin_path="$HOME/.tmux/plugins/$plugin"

  if [[ -d "$plugin_path/.git" ]]; then
    success "Found tmux plugin: $plugin"
  else
    warn "Missing tmux plugin: $plugin"
    ((failures += 1))
  fi
done

verify_socket="dotfiles-verify-$$"

if tmux -L "$verify_socket" -f "$HOME/.tmux.conf" new-session -d -s dotfiles-verify; then
  success "tmux configuration loads successfully"
else
  warn "tmux configuration failed to load."
  ((failures += 1))
fi

tmux -L "$verify_socket" kill-server >/dev/null 2>&1 || true

if [[ "$(defaults read com.apple.dock autohide 2>/dev/null)" == "1" ]]; then
  success "Dock autohide is enabled."
else
  warn "Dock autohide is not enabled."
  ((failures += 1))
fi

if [[ "$(defaults read com.apple.dock expose-group-apps 2>/dev/null)" == "1" ]]; then
  success "Dock application grouping is enabled."
else
  warn "Dock application grouping is not enabled."
  ((failures += 1))
fi

# verification finished
if ((failures > 0)); then
  fail "Verification found $failures problem(s)"
fi

success "All verification checks passed."
