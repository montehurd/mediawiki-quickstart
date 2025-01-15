#!/bin/bash

source "./docker/docker.sh"
source "./tests/utilities.sh"

test_component_with_own_docker_compose() {
  # Do fresh install first
  FORCE=1 SILENT=1 SKIP_COUNTDOWN=1 ./fresh_install 2>&1 | verboseOrDotPerLine ""
  if [ ! -d "./mediawiki" ]; then
    echo "mediawiki directory not created"
    return 1
  fi
  echo "Mediawiki directory created as expected"

  # Install Elastica extension
  SILENT=1 ./install extensions/Elastica 2>&1 | verboseOrDotPerLine ""
  if [ ! -d "./mediawiki/extensions/Elastica" ]; then
    echo "Elastica extension directory not created"
    return 1
  fi
  echo "Elastica extension directory present as expected"

  # Check if elasticsearch container is running
  if ! is_container_running "mediawiki-elasticsearch-1"; then
    echo "elasticsearch container not running"
    return 1
  fi
  echo "elasticsearch container running as expected"

  return 0
}