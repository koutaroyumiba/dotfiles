#!/usr/bin/env bash

DOTFILE_LINKS=(
  "configs/shell/bashrc|$HOME/.bashrc"
  "configs/shell/bash_profile|$HOME/.bash_profile"
  "configs/shell/bash_aliases|$HOME/.bash_aliases"
  "configs/shell/zshrc|$HOME/.zshrc"
  "configs/shell/zprofile|$HOME/.zprofile"

  "configs/aerospace|$HOME/.config/aerospace"
  "configs/nvim|$HOME/.config/nvim"
  "configs/mise/config.toml|$HOME/.config/mise/config.toml"
  "configs/tmux/tmux.conf|$HOME/.tmux.conf"
  "configs/wezterm/wezterm.lua|$HOME/.wezterm.lua"

  "bin|$HOME/bin"

  "configs/pi/AGENTS.md|$HOME/.pi/agent/AGENTS.md"
  "configs/pi/settings.json|$HOME/.pi/agent/settings.json"
  "configs/pi/extensions|$HOME/.pi/agent/extensions"
  "configs/pi/prompts|$HOME/.pi/agent/prompts"
  "configs/pi/themes|$HOME/.pi/agent/themes"
)
