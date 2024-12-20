#!/bin/bash

source "./docker/docker.sh"
source "./fresh_install"
source "./common/npm-dependencies.sh"

ensure_selenium_ready() {
  fresh_install_if_containers_not_running
  install_node_dependencies
  # TODO: consider moving the bash code below to a "sh" file that the docker exec runs in the container
  docker exec -i \
    -u $(id -u):$(id -g) \
    -e DISPLAY=mediawiki-novnc-1:0 \
    mediawiki-mediawiki-web-1 bash <<'EOF'
    set -e
    cp -f /var/local/install-browser-for-puppeteer-core.js /var/www/html/w/install-browser-for-puppeteer-core.js
    CHROME_PATH=$(node -e "
      require('dotenv').config();
      console.log(process.env.CHROME_PATH || '');
    ")
    if [ -z "$CHROME_PATH" ]; then
      echo "Installing Selenium browser binary..."
      CHROME_PATH=$(node install-browser-for-puppeteer-core.js)
      echo "CHROME_PATH=$CHROME_PATH" >> .env
    fi
    "$CHROME_PATH" --version
EOF
}
