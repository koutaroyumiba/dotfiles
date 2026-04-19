#!/usr/bin/env bash

input=$(cat)

# --- Data extraction ---
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
# Full context token count = input + cache_creation + cache_read (matches what /context reports)
ctx_input_tokens=$(echo "$input" | jq -r '
  if .context_window.current_usage != null then
    ((.context_window.current_usage.input_tokens // 0) +
     (.context_window.current_usage.cache_creation_input_tokens // 0) +
     (.context_window.current_usage.cache_read_input_tokens // 0))
  else empty end')
ctx_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

total_cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Helper: format a resets_at unix epoch as 5h duration "[Xh:Xm]".
fmt_five_hour() {
	local epoch="$1"
	[ -z "$epoch" ] && return
	local now
	now=$(date +%s)
	local diff=$((epoch - now))
	[ "$diff" -le 0 ] && echo "[now]" && return
	local hours=$((diff / 3600))
	local mins=$(((diff % 3600) / 60))
	printf "[%dh:%02dm]\n" "$hours" "$mins"
}

# Helper: format a resets_at unix epoch as 7d duration "[Xd:Xh:Xm]".
fmt_seven_day() {
	local epoch="$1"
	[ -z "$epoch" ] && return
	local now
	now=$(date +%s)
	local diff=$((epoch - now))
	[ "$diff" -le 0 ] && echo "[now]" && return
	local days=$((diff / 86400))
	local hours=$(((diff % 86400) / 3600))
	local mins=$(((diff % 3600) / 60))
	printf "[%dd:%dh:%02dm]\n" "$days" "$hours" "$mins"
}

# --- Git branch ---
git_branch=""
if [ -n "$cwd" ] && cd "$cwd" 2>/dev/null; then
	git_branch=$(GIT_OPTIONAL_LOCKS=0 git symbolic-ref --short HEAD 2>/dev/null ||
		GIT_OPTIONAL_LOCKS=0 git rev-parse --short HEAD 2>/dev/null)
fi

# --- ANSI colors (dim-friendly) ---
reset="\033[0m"
bold="\033[1m"
dim="\033[2m"

cyan="\033[36m"
yellow="\033[33m"
green="\033[32m"
blue="\033[34m"
magenta="\033[35m"
red="\033[31m"
white="\033[37m"

sep="${dim}|${reset}"

parts=()

# Git branch
if [ -n "$git_branch" ]; then
	parts+=("$(printf "${cyan} ${bold}%s${reset}" "$git_branch")")
fi

# Current working directory
if [ -n "$cwd" ]; then
	cwd_display="${cwd/#$HOME/~}"
	parts+=("$(printf "${magenta}%s${reset}" "$cwd_display")")
fi

# Model
parts+=("$(printf "${blue}%s${reset}" "$model")")

# Context window
if [ -n "$used_pct" ] && [ -n "$remaining_pct" ]; then
	used_int=$(printf '%.0f' "$used_pct")
	if [ "$used_int" -ge 80 ]; then
		ctx_color="$red"
	elif [ "$used_int" -ge 50 ]; then
		ctx_color="$yellow"
	else
		ctx_color="$green"
	fi
	# Build optional token count annotation (e.g. "90k/200k")
	ctx_tokens_str=""
	if [ -n "$ctx_input_tokens" ] && [ -n "$ctx_window_size" ]; then
		used_k=$(awk "BEGIN { printf \"%.0f\", $ctx_input_tokens / 1000 }")
		total_k=$(awk "BEGIN { printf \"%.0f\", $ctx_window_size / 1000 }")
		ctx_tokens_str=" ${dim}(${used_k}k/${total_k}k)${reset}"
	fi
	parts+=("$(printf "${dim}ctx${reset} ${ctx_color}%s%%${reset}%b" "$used_int" "$ctx_tokens_str")")
fi

# 5-hour session limit
if [ -n "$five_hour" ]; then
	pct_int=$(printf '%.0f' "$five_hour")
	if [ "$pct_int" -ge 80 ]; then
		lim_color="$red"
	elif [ "$pct_int" -ge 50 ]; then
		lim_color="$yellow"
	else
		lim_color="$green"
	fi
	resets_str=$(fmt_five_hour "$five_hour_resets")
	if [ -n "$resets_str" ]; then
		parts+=("$(printf "${dim}5h${reset} ${lim_color}%s%%${reset} ${dim}%s${reset}" "$pct_int" "$resets_str")")
	else
		parts+=("$(printf "${dim}5h${reset} ${lim_color}%s%%${reset}" "$pct_int")")
	fi
fi

# 7-day session limit
if [ -n "$seven_day" ]; then
	pct_int=$(printf '%.0f' "$seven_day")
	if [ "$pct_int" -ge 80 ]; then
		lim_color="$red"
	elif [ "$pct_int" -ge 50 ]; then
		lim_color="$yellow"
	else
		lim_color="$green"
	fi
	resets_str=$(fmt_seven_day "$seven_day_resets")
	if [ -n "$resets_str" ]; then
		parts+=("$(printf "${dim}7d${reset} ${lim_color}%s%%${reset} ${dim}%s${reset}" "$pct_int" "$resets_str")")
	else
		parts+=("$(printf "${dim}7d${reset} ${lim_color}%s%%${reset}" "$pct_int")")
	fi
fi

# Session cost
if [ -n "$total_cost_usd" ]; then
	cost_fmt=$(awk "BEGIN { printf \"%.2f\", $total_cost_usd }")
	parts+=("$(printf "${yellow}\$%s${reset}" "$cost_fmt")")
fi

# Vim mode
if [ -n "$vim_mode" ]; then
	case "$vim_mode" in
	INSERT) mode_color="$green" ;;
	NORMAL) mode_color="$yellow" ;;
	*) mode_color="$white" ;;
	esac
	parts+=("$(printf "${mode_color}${bold}%s${reset}" "$vim_mode")")
fi

# --- Assemble ---
line=""
for part in "${parts[@]}"; do
	if [ -z "$line" ]; then
		line="$part"
	else
		line="$line $(printf '%b' "$sep") $part"
	fi
done

printf "%b\n" "$line"
