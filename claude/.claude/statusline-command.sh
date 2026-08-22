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

# --- Rate-limit token estimates ---
# The statusline payload only carries a percentage for the 5h/7d windows, no
# absolute token counts. To show a fraction we sum tokens seen in the local
# transcripts for each window and back out an implied budget:
#   budget = tokens_in_window / (used_percentage / 100)
# Local transcripts only, so this misses usage from other machines, and the
# real limits are weighted per model -- treat both numbers as estimates.
usage_cache="$HOME/.claude/.statusline-usage-cache.json"
usage_cache_ttl=60

refresh_usage_cache() {
	local now cutoff5 cutoff7 tmp
	now=$(date -u +%s)
	cutoff5=$(date -u -r $((now - 18000)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || return
	cutoff7=$(date -u -r $((now - 604800)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || return
	tmp="${usage_cache}.$$"
	# -mmin 10140 = 7 days + a 1h slop for clock/timezone skew.
	find "$HOME/.claude/projects" -name '*.jsonl' -mmin -10140 -print0 2>/dev/null |
		xargs -0 jq -n --arg c5 "$cutoff5" --arg c7 "$cutoff7" --argjson now "$now" '
			reduce inputs as $e ({seen: {}, five_hour: 0, seven_day: 0};
			  if ($e.message.usage != null and ($e.timestamp // "") >= $c7) then
			    (($e.message.id // $e.uuid // "") + "|" + ($e.timestamp // "")) as $id
			    | if .seen[$id] then . else
			        .seen[$id] = true
			        | ($e.message.usage
			           | (.input_tokens // 0) + (.cache_creation_input_tokens // 0)
			             + (.cache_read_input_tokens // 0) + (.output_tokens // 0)) as $n
			        | .five_hour += (if ($e.timestamp >= $c5) then $n else 0 end)
			        | .seven_day += $n
			      end
			  else . end)
			| {ts: $now, five_hour, seven_day}' >"$tmp" 2>/dev/null &&
		mv -f "$tmp" "$usage_cache" || rm -f "$tmp"
}

cache_age=$usage_cache_ttl
if [ -f "$usage_cache" ]; then
	cache_ts=$(jq -r '.ts // 0' "$usage_cache" 2>/dev/null || echo 0)
	cache_age=$(($(date +%s) - cache_ts))
fi
# Serve the cached numbers now; rebuild in the background when stale so the
# statusline never blocks on scanning ~40MB of transcripts.
if [ "$cache_age" -ge "$usage_cache_ttl" ] && [ ! -f "${usage_cache}.lock" ]; then
	(
		touch "${usage_cache}.lock"
		refresh_usage_cache
		rm -f "${usage_cache}.lock"
	) >/dev/null 2>&1 &
	disown 2>/dev/null
fi

five_hour_tokens=""
seven_day_tokens=""
if [ -f "$usage_cache" ]; then
	five_hour_tokens=$(jq -r '.five_hour // empty' "$usage_cache" 2>/dev/null)
	seven_day_tokens=$(jq -r '.seven_day // empty' "$usage_cache" 2>/dev/null)
fi

# Helper: render a token count as "820k" / "4.2M".
fmt_tokens() {
	awk "BEGIN {
		n = $1
		if (n >= 1000000) printf \"%.1fM\", n / 1000000
		else printf \"%.0fk\", n / 1000
	}"
}

# Helper: "(1.2M/2.9M)" from tokens used + used percentage.
fmt_token_fraction() {
	local tokens="$1" pct="$2" budget
	[ -z "$tokens" ] && return
	awk "BEGIN { exit !($pct > 0.5) }" || return
	budget=$(awk "BEGIN { printf \"%.0f\", $tokens / ($pct / 100) }")
	printf " %b(%s/%s)%b" "$dim" "$(fmt_tokens "$tokens")" "$(fmt_tokens "$budget")" "$reset"
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
	tokens_str=$(fmt_token_fraction "$five_hour_tokens" "$five_hour")
	if [ -n "$resets_str" ]; then
		parts+=("$(printf "${dim}5h${reset} ${lim_color}%s%%${reset}%b ${dim}%s${reset}" "$pct_int" "$tokens_str" "$resets_str")")
	else
		parts+=("$(printf "${dim}5h${reset} ${lim_color}%s%%${reset}%b" "$pct_int" "$tokens_str")")
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
	tokens_str=$(fmt_token_fraction "$seven_day_tokens" "$seven_day")
	if [ -n "$resets_str" ]; then
		parts+=("$(printf "${dim}7d${reset} ${lim_color}%s%%${reset}%b ${dim}%s${reset}" "$pct_int" "$tokens_str" "$resets_str")")
	else
		parts+=("$(printf "${dim}7d${reset} ${lim_color}%s%%${reset}%b" "$pct_int" "$tokens_str")")
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
