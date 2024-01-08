#!/bin/bash

set -eu

get_response_code() {
  # shellcheck disable=SC2005
  echo "$(curl --write-out '%{http_code}' --silent --output /dev/null "$1")"
}

open_url_with_linux_browser() {
  local url
  url="$1"
  if command -v google-chrome &> /dev/null; then
    google-chrome "$url" &> /dev/null &
    return 0
  elif command -v chromium &> /dev/null; then
    chromium "$url" &> /dev/null &
    return 0
  fi
  if command -v xdg-open &> /dev/null; then
    xdg-open "$url" &> /dev/null
    return 0
  fi
  return 1
}

open_url_when_available() {
  local error_message
  local url
  url="$1"
  wait_until_url_available "$url"
  error_message="Unable to automatically open '$url', try opening it in a browser"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS system
    open ${2:+-a "$2"} "$url" || echo "$error_message"
  elif [[ "$(uname -r)" == *microsoft* ]]; then
    # Windows Subsystem for Linux
    if which explorer.exe > /dev/null; then
      explorer.exe "$url" || true
    elif [ -f /mnt/c/WINDOWS/explorer.exe ]; then
      /mnt/c/WINDOWS/explorer.exe "$url" || true
    else
      echo "explorer.exe not found."
    fi
  elif [[ "$OSTYPE" == "linux-gnu" ]] || [[ "$OSTYPE" == "linux" ]]; then
    # Linux system
    open_url_with_linux_browser "$url" || echo "$error_message"
  else
    echo "$error_message"
    echo "Unsupported operating system"
  fi
}

wait_until_url_available() {
  local url
  local max_wait
  local elapsed_time
  url="$1"
  max_wait="${2:-}" # Provide a default value for max_wait if $2 is not set (unset means we want infinite wait)
  elapsed_time=0
  while ! [[ "$(get_response_code "$url")" =~ ^(200|301)$ ]]; do
    sleep 1
    if [ -n "$max_wait" ]; then
      ((elapsed_time++))
      if [ "$elapsed_time" -ge "$max_wait" ]; then
        echo "Timed out waiting for URL to be available."
        return 1
      fi
    fi
  done
  sleep 1
}

confirm_action() {
  local prompt_message
  prompt_message="$1"
  local force_mode
  force_mode=${FORCE:-""}
  if [[ "$force_mode" == "1" ]] || [[ "$force_mode" == "true" ]]; then
    return 0
  else
    read -p "${prompt_message} (y/n)? " -n 1 -r
    echo
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
      return 1
    fi
    return 0
  fi
}

print_force_mode_notification_if_necessary() {
  local force_mode
  force_mode=${FORCE:-""}
  local skip_countdown
  skip_countdown=${SKIP_COUNTDOWN:-""}
  local interrupted
  interrupted=0
  if [[ "$force_mode" != "1" ]] && [[ "$force_mode" != "true" ]]; then
    return 0
  fi
  if [[ "$skip_countdown" == "1" ]] || [[ "$skip_countdown" == "true" ]]; then
    return 0
  fi
  handle_interrupt() {
    interrupted=1
    # Clear the line to remove any partial countdown message
    echo -ne "\r\033[K"
    # Show cursor and add a new line for clean exit
    echo -ne "\033[?25h\n"
    echo 'Fresh install canceled'
    exit
  }
  # Trap the interrupt signal (Control-C) and call handle_interrupt
  trap handle_interrupt SIGINT
  echo -ne "\033[?25l"
  for i in {10..1}; do
    echo -ne "\r\033[K\033[33mStarting fresh install in $i seconds. Press Control-c to cancel\033[0m"
    sleep 1
    if [[ $interrupted -eq 1 ]]; then
      return
    fi
  done
  # Clear the line before displaying the final message
  echo -ne "\r\033[K"
  echo -ne "\033[?25h"
  echo 'Starting fresh install...'
  # Reset the trap to default behavior
  trap - SIGINT
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
