#!/bin/bash
# Claude Code Enhanced Analytics Status Line
# Line 1: session state (model, duration, code changes, tokens, context)
# Line 2: plan rate limits (5-hour rolling window, weekly window)

RESET="\033[0m"
DIM="\033[2m"
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
MAGENTA="\033[35m"

input=$(cat)

# Format an integer token count as "1.2K" / "94K" / "1.2M"
human_tokens() {
  local n=$1
  if [ "$n" -lt 1000 ]; then
    printf "%d" "$n"
  elif [ "$n" -lt 10000 ]; then
    printf "%d.%dK" $((n / 1000)) $(((n % 1000) / 100))
  elif [ "$n" -lt 1000000 ]; then
    printf "%dK" $((n / 1000))
  else
    printf "%d.%dM" $((n / 1000000)) $(((n % 1000000) / 100000))
  fi
}

# Render a 10-char progress bar from a percentage (accepts floats)
make_bar() {
  local pct_int=${1%.*}
  [ -z "$pct_int" ] && pct_int=0
  local width=10
  local filled=$((pct_int * width / 100))
  [ $filled -gt $width ] && filled=$width
  [ $filled -lt 0 ] && filled=0
  local empty=$((width - filled))
  local i
  for ((i = 0; i < filled; i++)); do printf "▓"; done
  for ((i = 0; i < empty; i++)); do printf "░"; done
}

# Format a unix-epoch reset time as a clock/date in Europe/Madrid (English).
# Today      -> "14:30"
# Tomorrow   -> "tomorrow 02:15"
# This week  -> "Mon 14:30"
# Further    -> "Apr 28 14:30"
format_reset() {
  local resets_at=$1
  local now diff today_date reset_date tomorrow_date reset_time
  now=$(date +%s)
  diff=$((resets_at - now))
  if [ $diff -le 0 ]; then
    printf "now"
    return
  fi
  today_date=$(TZ=Europe/Madrid date +%Y-%m-%d)
  tomorrow_date=$(TZ=Europe/Madrid date -v+1d +%Y-%m-%d)
  reset_date=$(TZ=Europe/Madrid date -r "$resets_at" +%Y-%m-%d)
  reset_time=$(TZ=Europe/Madrid date -r "$resets_at" +%H:%M)
  if [ "$reset_date" = "$today_date" ]; then
    printf "%s" "$reset_time"
  elif [ "$reset_date" = "$tomorrow_date" ]; then
    printf "tomorrow %s" "$reset_time"
  elif [ $diff -lt 604800 ]; then
    LC_TIME=C TZ=Europe/Madrid date -r "$resets_at" +'%a %H:%M'
  else
    LC_TIME=C TZ=Europe/Madrid date -r "$resets_at" +'%b %d %H:%M'
  fi
}

# Pick color for plan-limit percentages: <60 green, 60-85 yellow, >=85 red
plan_color() {
  local pct_int=${1%.*}
  [ -z "$pct_int" ] && pct_int=0
  if [ $pct_int -lt 60 ]; then
    printf "%b" "$GREEN"
  elif [ $pct_int -lt 85 ]; then
    printf "%b" "$YELLOW"
  else
    printf "%b" "$RED"
  fi
}

# === Model ===
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
model_short=$(echo "$model" | sed 's/Claude //' | sed 's/ 20[0-9]*//')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# === Session metrics ===
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
duration_sec=$((duration_ms / 1000))
duration_min=$((duration_sec / 60))
duration_remaining=$((duration_sec % 60))

lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# === Context window: absolute tokens loaded right now + percentage ===
usage=$(echo "$input" | jq '.context_window.current_usage')
ctx_tokens=0
ctx_pct=0
if [ "$usage" != "null" ]; then
  cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
  cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
  input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
  ctx_tokens=$((input_tokens + cache_creation + cache_read))
  context_size=$(echo "$input" | jq '.context_window.context_window_size // 1')
  ctx_pct=$((ctx_tokens * 100 / context_size))
fi

# Ctx color: by absolute tokens. <100K green, 100K-160K yellow, >=160K red
if [ $ctx_tokens -lt 100000 ]; then
  ctx_color="$GREEN"
elif [ $ctx_tokens -lt 160000 ]; then
  ctx_color="$YELLOW"
else
  ctx_color="$RED"
fi

# === Duration ===
if [ $duration_min -gt 0 ]; then
  duration_display="${duration_min}m ${duration_remaining}s"
else
  duration_display="${duration_sec}s"
fi

# === Line 1 ===
printf "${BOLD}${BLUE}%s${RESET}" "$model_short"
if [ -n "$effort" ]; then
  printf " ${DIM}%s${RESET}" "$effort"
fi
printf " ${DIM}│${RESET} "

printf "${DIM}⏱ ${RESET}%s" "$duration_display"
printf " ${DIM}│${RESET} "

if [ $lines_added -gt 0 ] || [ $lines_removed -gt 0 ]; then
  printf "${GREEN}+%d${RESET} ${RED}-%d${RESET}" "$lines_added" "$lines_removed"
  printf " ${DIM}│${RESET} "
fi

printf "${MAGENTA}↑${RESET}%s ${MAGENTA}↓${RESET}%s" "$(human_tokens "$total_input")" "$(human_tokens "$total_output")"
printf " ${DIM}│${RESET} "

printf "${ctx_color}ctx %s (%d%%)${RESET}" "$(human_tokens "$ctx_tokens")" "$ctx_pct"

# === Line 2: plan rate limits ===
printf "\n"

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$five_pct" ]; then
  c=$(plan_color "$five_pct")
  printf "${DIM}5h${RESET} ${c}%s${RESET} ${c}%d%%${RESET} ${DIM}·${RESET} ${DIM}%s${RESET}" \
    "$(make_bar "$five_pct")" "${five_pct%.*}" "$(format_reset "$five_reset")"
else
  printf "${DIM}5h —${RESET}"
fi

printf "    "

if [ -n "$seven_pct" ]; then
  c=$(plan_color "$seven_pct")
  printf "${DIM}7d${RESET} ${c}%s${RESET} ${c}%d%%${RESET} ${DIM}·${RESET} ${DIM}%s${RESET}" \
    "$(make_bar "$seven_pct")" "${seven_pct%.*}" "$(format_reset "$seven_reset")"
else
  printf "${DIM}7d —${RESET}"
fi
