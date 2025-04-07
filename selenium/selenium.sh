#!/bin/bash

source "./common/container-readiness.sh"
source "./common/utility.sh"

ensure_selenium_ready() {
  echo | verboseOrDotPerLine "Ensuring Selenium ready..."
  fresh_install_if_containers_not_running

  if [ "${SILENT:-0}" -ne 1 ]; then
    if ! is_service_running "novnc"; then
      docker compose up -d novnc 2>&1 | verboseOrDotPerLine "Starting NoVNC container"
    fi
    open_url_when_available "http://localhost:8086/vnc_lite.html?autoconnect=true" 2>&1 | verboseOrDotPerLine "Waiting for NoVNC page availability"
  fi

  if ! ./shellto s /var/local/install-browser-for-puppeteer-core.sh; then
    echo
    exit 1
  fi
}