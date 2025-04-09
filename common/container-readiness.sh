#!/bin/bash

source "./docker/docker.sh"
source "./fresh_install"

fresh_install_if_containers_not_running() {
  if are_containers_running "mediawiki-mediawiki-1" "mediawiki-mediawiki-web-1" "mediawiki-mediawiki-jobrunner-1"; then
    return
  fi
  echo
  echo "Mediawiki containers are not running..."
  fresh_install
}