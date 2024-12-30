#!/bin/bash

source "./common/container-readiness.sh"

ensure_selenium_ready() {
  fresh_install_if_containers_not_running
  ./shellto -e DISPLAY=mediawiki-novnc-1:0 w /var/local/install-browser-for-puppeteer-core.sh
}