#!/bin/bash

ensure_submodule_initialized_and_updated() {
  local submodule
  local before_update_sha
  local after_update_sha
  submodule="$1"
  if [ ! -e "./$submodule/.git" ]; then
    git submodule update --init --recursive --remote "$submodule"
    echo "Submodule '$submodule' was updated (initial fetch)"
    return 0
  else
    before_update_sha=$(git -C "./$submodule" rev-parse HEAD)
    git submodule update --recursive "$submodule"
    after_update_sha=$(git -C "./$submodule" rev-parse HEAD)
    if [ "$before_update_sha" != "$after_update_sha" ]; then
      echo "Submodule '$submodule' was updated"
      return 0
    fi
    echo "Submodule '$submodule' is already up to date"
    return 1
  fi
}

source_up_to_date_submodule_file() {
  local submodule
  local file
  local submodule_path
  submodule="$1"
  file="$2"
  submodule_path="./$submodule/$file"
  ensure_submodule_initialized_and_updated "$submodule"
  if [ ! -f "$submodule_path" ]; then
    echo "Error: '$submodule_path' not found. Submodule update might have failed." >&2
    exit 1
  fi
  source "$submodule_path"
}