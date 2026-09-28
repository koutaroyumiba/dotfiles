#!/usr/bin/env bash
set -Eeuo pipefail

source "${DOTFILES_DIR:?}/lib/common.sh"

step_name="$(basename "$0" .sh)"
info "Placeholder installer: $step_name (DRY_RUN=${DRY_RUN:-0})"
