#!/bin/bash

docker_compose_wrapper() {
  COMPOSE_FILES="-f docker-compose.yml"
  OVERRIDE_FILE="docker-compose.override.yml"
  SELENIUM_FILE="docker-compose.selenium.yml"

  # Check if docker-compose.override.yml exists
  if [ -f "$OVERRIDE_FILE" ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f $OVERRIDE_FILE"
  fi

  # Check if USE_SELENIUM_YML environment variable is set to true
  if [ "$USE_SELENIUM_YML" = "true" ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f $SELENIUM_FILE"
  fi

  cd "$1" || exit 1

  docker compose $COMPOSE_FILES "${@:2}"
}