#!/bin/bash

source "./common/container-readiness.sh"
source "./common/utility.sh"

ensure_selenium_ready() {
  echo | verboseOrDotPerLine "Ensuring Selenium ready..."
  fresh_install_if_containers_not_running
  if ! ./shellto -e DISPLAY=mediawiki-novnc-1:0 w /var/local/install-browser-for-puppeteer-core.sh; then
    echo
    exit 1
  fi
}