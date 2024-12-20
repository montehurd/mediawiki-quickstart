#!/bin/bash

source "./docker/docker.sh"
source "./fresh_install"

fresh_install_if_containers_not_running() {
  if are_containers_running "mediawiki-mediawiki-1" "mediawiki-mediawiki-web-1" "mediawiki-mediawiki-jobrunner-1" "mediawiki-novnc-1"; then
    return
  fi
  # TODO: output a better message here and maybe the option to start instead of fresh install 
  echo
  echo "Mediawiki containers are not running..."
  fresh_install
}

install_node_dependencies() {
  docker exec -i \
    -u $(id -u):$(id -g) \
    mediawiki-mediawiki-web-1 bash /var/local/node-preparation.sh install_node_dependencies
}
