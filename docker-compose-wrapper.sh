#!/bin/bash

set -eu

source "./config"

docker_compose_wrapper() {
  local compose_files
  local override_file
  local selenium_file

  compose_files="-f docker-compose.yml"
  override_file="docker-compose.override.yml"
  selenium_file="docker-compose.selenium.yml"

  # Check if docker-compose.override.yml exists
  if [ -f "$override_file" ]; then
    compose_files="$compose_files -f $override_file"
  fi

  # Check if USE_SELENIUM_YML environment variable is set to true
  if [ -n "${USE_SELENIUM_YML:-}" ] && [ "$USE_SELENIUM_YML" = "true" ] && [ -f "$selenium_file" ]; then
    compose_files="$compose_files -f $selenium_file"
  fi

  cd "$1" || return 1

  # shellcheck disable=SC2086
  docker compose $compose_files "${@:2}"
}

docker_compose() {
  docker_compose_wrapper "$MEDIAWIKI_PATH" "$@"
}
