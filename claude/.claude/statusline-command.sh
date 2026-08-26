#!/usr/bin/env bash

input=$(cat)

# --- Data extraction ---
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Per-prompt context delta ---
# The statusline re-renders many times per turn, so a naive "current minus
# previous render" is 0 most of the time. Instead keep the last *changed*
# value in a per-session state file: when context usage moves, record the jump
# and keep showing it until it moves again. That jump is the last prompt's
# contribution.
session_id=$(echo "$input" | jq -r '.session_id // empty')
state_dir="$HOME/.claude/statusline-state"
state_file=""
[ -n "$session_id" ] && state_file="$state_dir/${session_id}.json"

prev_state="{}"
if [ -n "$state_file" ] && [ -f "$state_file" ]; then
	prev_state=$(cat "$state_file" 2>/dev/null || echo "{}")
fi

# Emits {v: <value>, d: <delta>}; the delta carries over until the value moves.
new_state=$(jq -nc \
	--argjson prev "$prev_state" \
	--arg ctx "${used_pct:-}" '
	if $ctx == "" then {ctx: ($prev.ctx // {v: 0, d: 0})}
	else
	  ($ctx | tonumber) as $cur
	  | ($prev.ctx.v // null) as $old
	  | {ctx:
	      (if $old == null then {v: $cur, d: 0}
	       elif ($cur - $old | fabs) < 0.05 then {v: $old, d: ($prev.ctx.d // 0)}
	       else {v: $cur, d: ($cur - $old)}
	       end)}
	end')

if [ -n "$state_file" ]; then
	mkdir -p "$state_dir" 2>/dev/null
	printf '%s\n' "$new_state" >"$state_file" 2>/dev/null
	# Prune state from sessions untouched for a week.
	find "$state_dir" -name '*.json' -mtime +7 -delete 2>/dev/null
fi

ctx_delta=$(echo "$new_state" | jq -r '.ctx.d // 0')

# Helper: " (+3%)" from a delta; nothing below 0.1 points or for a decrease
# (context compaction).
fmt_delta() {
	local d="$1"
	awk "BEGIN { exit !($d >= 0.1) }" 2>/dev/null || return
	printf " %b(+%s%%)%b" "$dim" "$(awk "BEGIN { if ($d >= 1) printf \"%.0f\", $d; else printf \"%.1f\", $d }")" "$reset"
}

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
	parts+=("$(printf "${dim}ctx${reset} ${ctx_color}%s%%${reset}%b" "$used_int" "$(fmt_delta "$ctx_delta")")")
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
