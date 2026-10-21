#!/bin/sh
input=$(cat)

# --- Directory + Git branch ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")

git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && git_branch=" ($branch)"
fi

# --- Model + Context + Effort ---
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Read effort level from live session input
effort=$(echo "$input" | jq -r '.effort.level // empty')

if [ -n "$used" ]; then
  context_info=$(printf "%.0f%%" "$used")
  model_ctx="$model  ctx:$context_info"
else
  model_ctx="$model"
fi

if [ -n "$effort" ]; then
  model_ctx="$model_ctx  effort:$effort"
fi

# --- Session rate limit progress bar ---
# Build a 10-char bar: filled = █, empty = ░
make_bar() {
  pct="$1"
  filled=$(awk "BEGIN {x = $pct * 10 / 100; printf \"%.0f\", (x > 10 ? 10 : x)}")
  [ "$filled" -gt 10 ] && filled=10
  empty=$((10 - filled))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i+1)); done
  i=0
  while [ "$i" -lt "$empty" ]; do bar="${bar}░"; i=$((i+1)); done
  printf "%s" "$bar"
}

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

session_info=""
session_color=""

if [ -n "$five_pct" ]; then
  bar=$(make_bar "$five_pct")

  # Determine color based on usage: green <50%, yellow 50-80%, red >80%
  pct_int=$(printf "%.0f" "$five_pct")
  if [ "$pct_int" -ge 80 ]; then
    session_color="\033[31m"   # red
  elif [ "$pct_int" -ge 50 ]; then
    session_color="\033[33m"   # yellow
  else
    session_color="\033[32m"   # green
  fi

  # Format reset time as HH:MM if available
  reset_str=""
  if [ -n "$five_resets_at" ]; then
    reset_time=$(date -r "$five_resets_at" "+%H:%M" 2>/dev/null)
    [ -n "$reset_time" ] && reset_str=" rst:$reset_time"
  fi

  session_info=$(printf "5h:%s %.0f%%%s" "$bar" "$five_pct" "$reset_str")
fi

# --- Combined output with ANSI colors ---
if [ -n "$session_info" ]; then
  printf "\033[34m%s%s\033[0m  \033[33m%s\033[0m  %b%s\033[0m" "$dir" "$git_branch" "$model_ctx" "$session_color" "$session_info"
else
  printf "\033[34m%s%s\033[0m  \033[33m%s\033[0m" "$dir" "$git_branch" "$model_ctx"
fi
