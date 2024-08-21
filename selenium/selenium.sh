#!/bin/bash

source "./docker/docker.sh"
source "./fresh_install"

ensure_selenium_ready() {
  if ! are_containers_running "mediawiki-mediawiki-1" "mediawiki-mediawiki-web-1" "mediawiki-mediawiki-jobrunner-1" "mediawiki-novnc-1"; then
    # TODO: output a better message here and maybe the option to start instead of fresh install 
    echo
    echo "Mediawiki containers are not running..."
    fresh_install
  fi
  # TODO: consider moving the bash code below to a "sh" file that the docker exec runs in the container
  docker exec -i -u root \
    -e DISPLAY=mediawiki-novnc-1:0 \
    mediawiki-mediawiki-web-1 bash <<'EOF'
    set -e
    if [ ! -d "node_modules" ]; then
      npm ci
    else
      npm install
    fi
    cp -f /var/local/wdio.conf.override.js /var/www/html/w/tests/selenium/wdio.conf.override.js
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
