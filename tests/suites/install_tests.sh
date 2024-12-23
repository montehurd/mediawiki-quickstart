#!/bin/bash

test_fresh_install() {
  FORCE=1 SILENT=1 SKIP_COUNTDOWN=1 ./fresh_install 2>&1 | verboseOrDotPerLine ""
  if [ ! -d "./mediawiki" ]; then
    echo "mediawiki directory not created"
    return 1
  fi
  echo "Mediawiki directory created as expected"
  if ! docker ps | grep -q "mediawiki-mediawiki-1"; then
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

test_mediawiki_web_image_consistency() {
  local mediawiki_base_image
  mediawiki_base_image=$(_yq '.services."mediawiki-web".image' "$(cat "$MEDIAWIKI_PATH/docker-compose.yml")")
  if [ -z "$mediawiki_base_image" ]; then
    echo "Error: Could not determine mediawiki-web base image"
    return 1
  fi

  local selenium_from_image
  selenium_from_image=$(grep '^FROM' "./selenium/Dockerfile.mediawiki-web.selenium" | sed 's/FROM //')

  if [ "$mediawiki_base_image" != "$selenium_from_image" ]; then
    echo "Image mismatch detected"
    echo "Dockerfile.mediawiki-web.selenium needs to use the same image as the core Mediawiki docker-compose.yml (since it's just adding a couple layers to it):"
    echo "mediawiki/docker-compose.yml uses:"
    echo -e "\t$mediawiki_base_image"
    echo "Dockerfile.mediawiki-web.selenium uses:"
    echo -e "\t$selenium_from_image"
    echo "Likely what happened is Mediawiki's docker-compose.yml was updated to use a newer image, so Dockerfile.mediawiki-web.selenium will need to be updated to use the same newer image too"
    return 1
  fi

  echo "Images match: $mediawiki_base_image"
  return 0
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
