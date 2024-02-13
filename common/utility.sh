#!/bin/bash

set -eu

ensure_utilities_present() {
  local UTILITY_PATH
  UTILITY_PATH="./shell-utilities/utilities.sh"
  if [ ! -f "$UTILITY_PATH" ]; then
    git submodule update --init --recursive --remote shell-utilities
  fi
  git submodule update --recursive shell-utilities
  if [ -f "$UTILITY_PATH" ]; then
    source "$UTILITY_PATH"
  else
    echo "Error: '$UTILITY_PATH' not found. Submodule update might have failed." >&2
    exit 1
  fi
}

ensure_utilities_present "$@"