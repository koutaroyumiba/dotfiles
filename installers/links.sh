#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"
source "$DOTFILES_DIR/profiles/macos.sh"

nearest_existing_parent() {
  local path="$1"
  local next

  while [[ ! -e "$path" && ! -L "$path" ]]; do
    next="$(dirname "$path")"

    if [[ "$next" == "$path" ]]; then
      break
    fi

    path="$next"
  done

  printf "%s\n" "$path"
}

conflicts=0

# readonly pass - validation
for mapping in "${DOTFILE_LINKS[@]}"; do
  relative_source="${mapping%%|*}"
  target="${mapping#*|}"
  source_path="$DOTFILES_DIR/$relative_source"

  if [[ ! -e "$source_path" ]]; then
    warn "Missing repository source: $source_path"
    ((conflicts += 1))
    continue
  fi

  if [[ -L "$target" ]]; then
    current_source="$(readlink "$target")"

    if [[ "$current_source" != "$source_path" ]]; then
      warn "Conflicting symlink: $target -> $current_source"
      warn "Expected: $target -> $source_path"
      ((conflicts += 1))
    fi
  elif [[ -e "$target" ]]; then
    warn "Conflicting existing path: $target"
    ((conflicts += 1))
  else
    parent="$(nearest_existing_parent "$(dirname "$target")")"

    if [[ ! -d "$parent" ]]; then
      warn "Target parent is not a directory: $parent"
      warn "Unable to create target: $target"
      ((conflicts += 1))
    fi
  fi
done

if ((conflicts > 0)); then
  fail "Found $conflicts link conflict(s). No links were changed."
fi

# second pass for linking
for mapping in "${DOTFILE_LINKS[@]}"; do
  relative_source="${mapping%%|*}"
  target="${mapping#*|}"
  source_path="$DOTFILES_DIR/$relative_source"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source_path" ]]; then
    success "Link already correct: $target"
    continue
  fi

  success "Creating a symlink: $source_path -> $target"
  run mkdir -p "$(dirname "$target")"
  run ln -s "$source_path" "$target"
done
