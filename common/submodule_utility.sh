#!/bin/bash

ensure_submodule_initialized_and_updated() {
  local submodule
  submodule="$1"
  if [ ! -e "./$submodule/.git" ]; then
    git submodule update --init --recursive --remote "$submodule"
  else
    git submodule update --recursive "$submodule"
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