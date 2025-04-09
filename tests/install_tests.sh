#!/bin/bash

source "./config"
source "./docker.sh"

# 'set +e' needed to allow subsequents tests to proceed if a test fails
# Needed here because the docker file turns it off
set +e

test_fresh_install() {
  FORCE=1 SILENT=1 SKIP_COUNTDOWN=1 ./fresh_install 2>&1 | verboseOrDotPerLine ""
  if [ ! -d "./mediawiki" ]; then
    echo "mediawiki directory not created"
    return 1
  fi
  echo "Mediawiki directory created as expected"
  if ! is_service_running "mediawiki"; then
    echo "mediawiki container not running"
    return 1
  fi
  echo "Mediawiki container running as expected"
  if ! curl -s -f -o /dev/null --retry 4 --retry-delay 2 --retry-max-time 15 -w "%{http_code}" "http://localhost:8080/wiki/Special:Version" | grep -q "200"; then
    echo "Special:Version page not responding with 200"
    return 1
  fi
  echo "Special:Version page accessible as expected"
  return 0
}

ensure_image_consistency() {
  local service_name="$1"
  local dockerfile_url="$2"

  # Get base image from docker-compose.yml for the specified service
  local base_image
  base_image=$(_yq ".services.\"$service_name\".image" "$(cat "$MEDIAWIKI_PATH/docker-compose.yml")")
  if [ -z "$base_image" ]; then
    echo "Error: Could not determine '$service_name' base image"
    return 1
  fi

  # Get FROM image from the specified Dockerfile
  local from_image
  from_image=$(curl -fsSL "$dockerfile_url" | grep '^FROM' | sed 's/FROM //')
  if [ -z "$from_image" ]; then
    echo "Error: Could not parse FROM image from '$dockerfile_url'"
    return 1
  fi

  if [ "$base_image" != "$from_image" ]; then
    echo "Image mismatch detected"
    echo "'$dockerfile_url' needs to use the same image as the '$service_name' service in Mediawiki's docker-compose.yml (since it's just adding layers to it):"
    echo "Mediawiki's docker-compose.yml '$service_name' service uses:"
    echo -e "\t$base_image"
    echo "'$dockerfile_url' uses:"
    echo -e "\t$from_image"
    echo "Likely what happened is docker-compose.yml was updated to use a newer image, so '$dockerfile_url' will need to be updated to use the same newer image too"
    return 1
  fi

  echo "Images match for '$service_name': '$base_image'"
  return 0
}

test_mediawiki_image_consistency() {
  ensure_image_consistency "mediawiki" "https://gitlab.wikimedia.org/mhurd/mediawiki-docker-images/-/raw/main/mediawiki/Dockerfile?ref_type=heads"
}

test_no_files_owned_by_root() {
  output=$(SILENT=1 ./shellto w find . -user root 2>&1)
  if [ -z "$output" ]; then
    echo "No files owned by root found in the mediawiki folder in the web container"
    return 0
  else
    echo "Files owned by root found in the mediawiki folder in the web container:"
    echo "$output"
    return 1
  fi
}
