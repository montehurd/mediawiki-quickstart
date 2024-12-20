#!/bin/bash

source "./docker/docker.sh"
source "./fresh_install"

ensure_npm_ready() {
  if ! are_containers_running "mediawiki-mediawiki-1" "mediawiki-mediawiki-web-1" "mediawiki-mediawiki-jobrunner-1" "mediawiki-novnc-1"; then
    # TODO: output a better message here and maybe the option to start instead of fresh install 
    echo
    echo "Mediawiki containers are not running..."
    fresh_install
  fi
  docker exec -i \
    -u $(id -u):$(id -g) \
    mediawiki-mediawiki-web-1 bash /var/local/node-preparation.sh install_node_dependencies
}
