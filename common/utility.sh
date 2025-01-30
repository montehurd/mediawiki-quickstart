#!/bin/bash

set -eu

# snippet for testing verboseOrDotPerLine, add "VERBOSE=1 " before "bash" to test it in verbose mode
# bash -c 'source ./common/utility.sh && (echo "This is a test" && sleep 2 && echo "cha cha") | verboseOrDotPerLine "Hi there" "optional message with THIS=that test, and OTHER=123 test"'
verboseOrDotPerLine() {
  local title="$1"
  local additional_msg="${2:-}"
  local prefix="${3:-}"
  local GREEN='\033[0;32m'
  local BLUE='\033[0;34m'
  local NC='\033[0m'
  local msg=""

  highlight_key_value_pairs() {
    echo "$1" | sed -E "s/([A-Za-z_][A-Za-z0-9_]*=[^ ,)]+)/\\${BLUE}\1\\${NC}/g"
  }

  if [ -n "$title" ]; then
    if [ "${VERBOSE:-0}" != "1" ]; then
      msg="use VERBOSE=1 to see full output"
    fi
    if [ -n "$additional_msg" ]; then
      if [ -n "$msg" ]; then
        msg+=", $additional_msg"
      else
        msg="$additional_msg"
      fi
    fi
    if [ -n "$msg" ]; then
      msg=" ($(highlight_key_value_pairs "$msg"))"
    fi
    echo
    echo -e "${GREEN}${title}${NC}${msg}"
  fi

  if [ "${VERBOSE:-0}" = "1" ]; then
    if [ -n "$prefix" ]; then
      awk -v prefix="$prefix" -v GREEN="$GREEN" -v NC="$NC" 'BEGIN {
          RS = "\r|\n"
          LINE_PREFIX = GREEN prefix NC " "
      }
      {
          print LINE_PREFIX $0
          fflush()
      }'
    else
      cat
    fi
  else
    (echo && cat) | while IFS= read -r line || [ -n "$line" ]; do
      if [[ $line =~ ^($'\E'\[[0-9;]*m) ]]; then
        # Capture any ANSI escape codes at the beginning of the line
        color_code="${BASH_REMATCH[1]}"
        # Print the dot with the captured color code
        printf "%s▪${NC}" "${color_code}"
      else
        printf "▪"
      fi
    done
    echo
  fi
}

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
    if [ -f /mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe ]; then
      /mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe -Command "Start-Process '$url'"
    else
      echo "powershell.exe not found."
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
    echo "Response code for '$url' is: $(get_response_code "$url")"
    sleep 1
    if [ -n "$max_wait" ]; then
      ((elapsed_time++))
      if [ "$elapsed_time" -ge "$max_wait" ]; then
        printf "\e[31mTimed out waiting for '$url' to be available\e[0m\n"
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
    read -p "${prompt_message} (Y/n)? " -n 1 -r
    echo
    if [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]; then
      return 0
    fi
    return 1
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

_yq() {
  # Lets us use yq on the host even if it's not been installed
  # but avoids trying to do docker-in-docker in our containers
  # where we have installed yq
  if command -v yq >/dev/null 2>&1; then
    echo "$2" | yq eval "$1" -
  else
    echo "$2" | docker run -q --rm -i mikefarah/yq eval "$1" -
  fi
}

alpine_ansi2html() {
  docker run --rm -i python:alpine sh -c "
    echo '@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories &&
    apk update >/dev/null 2>&1 &&
    apk add --no-cache py3-ansi2html@testing >/dev/null 2>&1 &&
    cat | ansi2html
  "
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  "$@"
fi