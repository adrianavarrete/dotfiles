#!/bin/bash
# Claude Code Enhanced Analytics Status Line
# Displays model info, session metrics, token usage, costs, and context window

# ANSI color codes
RESET="\033[0m"
DIM="\033[2m"
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
MAGENTA="\033[35m"

# Read JSON input from stdin
input=$(cat)

# === Extract Model Info ===
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
# Shorten model name for better display
model_short=$(echo "$model" | sed 's/Claude //' | sed 's/ 20[0-9]*//')

# === Extract Session Metrics ===
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
duration_sec=$((duration_ms / 1000))
duration_min=$((duration_sec / 60))
duration_remaining=$((duration_sec % 60))

lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# === Extract Token Usage ===
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

# === Extract Cache Metrics ===
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
  cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
  cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
  input_tokens=$(echo "$usage" | jq '.input_tokens // 0')

  # Calculate cache efficiency
  total_cache=$((cache_read + cache_creation))
  if [ $total_cache -gt 0 ]; then
    cache_efficiency=$((cache_read * 100 / total_cache))
  else
    cache_efficiency=0
  fi

  # Calculate context percentage
  current_total=$((input_tokens + cache_creation + cache_read))
  context_size=$(echo "$input" | jq '.context_window.context_window_size // 1')
  context_pct=$((current_total * 100 / context_size))
else
  cache_efficiency=0
  context_pct=0
  total_cache=0
fi

# === Extract Cost ===
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# === Color-code Context Percentage ===
if [ $context_pct -lt 50 ]; then
  context_color="$GREEN"
elif [ $context_pct -lt 75 ]; then
  context_color="$YELLOW"
else
  context_color="$RED"
fi

# === Format Duration ===
if [ $duration_min -gt 0 ]; then
  duration_display="${duration_min}m ${duration_remaining}s"
else
  duration_display="${duration_sec}s"
fi

# === Build Status Line ===
printf "${BOLD}${BLUE}%s${RESET}" "$model_short"
printf " ${DIM}│${RESET} "

# Session duration
printf "${DIM}⏱ ${RESET}%s" "$duration_display"
printf " ${DIM}│${RESET} "

# Tokens with arrows
printf "${MAGENTA}↑${RESET}%'d ${MAGENTA}↓${RESET}%'d" "$total_input" "$total_output"
printf " ${DIM}│${RESET} "

# Code changes
if [ $lines_added -gt 0 ] || [ $lines_removed -gt 0 ]; then
  printf "${GREEN}+%d${RESET} ${RED}-%d${RESET}" "$lines_added" "$lines_removed"
  printf " ${DIM}│${RESET} "
fi

# Cache efficiency (only show if there's cache activity)
if [ $total_cache -gt 0 ]; then
  printf "${DIM}⚡${RESET}%d%%" "$cache_efficiency"
  printf " ${DIM}│${RESET} "
fi

# Context window with color coding
printf "${DIM}ctx${RESET} ${context_color}%d%%${RESET}" "$context_pct"
printf " ${DIM}│${RESET} "

# Cost in cyan to stand out
printf "${CYAN}\$%.4f${RESET}" "$total_cost"