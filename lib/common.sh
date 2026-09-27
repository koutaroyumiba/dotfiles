#!/usr/bin/env bash

# =======================
# == GENERAL UTILITIES ==
# =======================

# logging utilities
info()    { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
success() { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn()    { printf "\033[1;33m[WARN]\033[0m %s\n" "$*" >&2; }
fail()    { printf "\033[1;31m[FAIL]\033[0m %s\n" "$*" >&2; exit 1; }

# check if the first argument exists as a shell command
has_command() {
  command -v "$1" >/dev/null 2>&1
}

confirm() {
  local prompt="$1"
  local answer

  if [[ "${ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi

  read -r -p "$prompt [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

print_command() {
  printf "  $"
  printf " %q" "$@"
  printf "\n"
}

require_command() {
  has_command "$1" || fail "Required command not found: $1"
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail "This profile supports macOS only."
}

# ====================
# == COMMON SCRIPTS ==
# ====================

run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    print_command "$@"
    return 0
  fi

  "$@"
}

