#!/bin/bash

set -eu

get_response_code() {
  # shellcheck disable=SC2005
  echo "$(curl --write-out '%{http_code}' --silent --output /dev/null "$1")"
}

open_url_when_available() {
  wait_until_url_available "$1"
  error_message="Unable to automatically open '$1', try opening it in a browser"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS system
    open ${2:+-a "$2"} "$1" || echo "$error_message"
  elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    # Linux system
    xdg-open "$1" || echo "$error_message"
  elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows system (Cygwin, Git Bash, or WSL)
    start "" "$1" || echo "$error_message"
  else
    echo "Unsupported operating system"
  fi
}

wait_until_url_available() {
  while ! [[ "$(get_response_code "$1")" =~ ^(200|301)$ ]]; do sleep 1; done
  sleep 0.5
}

confirm_action() {
  local prompt_message
  prompt_message="$1"
  read -p "${prompt_message} (y/n)? " -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    return 1
  fi
  return 0
}

# Usage: print_duration_since_start start_time [format]
print_duration_since_start() {
  local start
  start=$1
  local format
  format=${2:-"Execution time: %d minutes, %d seconds."} # Use provided format, or default if not provided
  local end
  end=$(date +%s)
  local duration
  duration=$((end - start))
  local minutes
  minutes=$((duration / 60))
  local seconds
  seconds=$((duration % 60))
  # shellcheck disable=SC2059
  printf "$format\n" "$minutes" "$seconds"
}

is_dir_empty() {
  if [ ! "$(ls "$1")" ]; then
    return 0
  else
    return 1
  fi
}
