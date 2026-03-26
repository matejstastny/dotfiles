#!/usr/bin/env bash
# Claude Code status line

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

folder=$(basename "$cwd")

# Git branch
git_branch=""
if git_output=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch="$git_output"
elif git_output=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
  git_branch="$git_output"
fi

# Colors
white='\033[37m'
dim='\033[2m'
yellow='\033[33m'
red='\033[31m'
cyan='\033[36m'
reset='\033[0m'

out=""

# Directory
out+=$(printf "${white}${folder}${reset}")

# Git branch
if [ -n "$git_branch" ]; then
  out+=$(printf " ${dim}on${reset} ${cyan}${git_branch}${reset}")
fi

# Model
if [ -n "$model" ]; then
  out+=$(printf " ${dim}·${reset} ${dim}${model}${reset}")
fi

# Context usage
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    ctx_color="$red"
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="$yellow"
  else
    ctx_color="$dim"
  fi
  out+=$(printf " ${dim}·${reset} ${ctx_color}${used_int}%%${reset}")
fi

printf "%b" "$out"
