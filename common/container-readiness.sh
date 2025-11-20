#!/bin/bash

source "./docker.sh"
source "./fresh_install"

fresh_install_if_containers_not_running() {
  if are_services_running "mediawiki" "mediawiki-web" "mediawiki-jobrunner"; then
    return
  fi
  echo
  echo "Mediawiki containers are not running..."
  fresh_install
}
