#!/bin/bash

source "./config"
source "./common/utility.sh"
source "./docker/docker.sh"
source "./docker/docker-compose-wrapper.sh"
source "./fresh_install"

DOCKER_CHROMIUM_NOVNC_PATH="$SCRIPT_PATH/docker-chromium-novnc"

prepare_mediawiki_for_selenium() {
  export USE_SELENIUM_YML=true
  if ! fresh_install "$SCRIPT_PATH/selenium/docker-compose.selenium.yml"; then
    echo "Failed to do a fresh install"
    return 1
  fi
  if ! docker_compose exec -u "$HOST_UID:$HOST_GID" mediawiki ./selenium-preparation.sh apply_patch; then
    echo "Failed to apply patch"
    return 1
  fi
}

prepare_docker_chromium_novnc() {
  CHROMIUM_VERSION=$(docker exec -u root mediawiki-mediawiki-1 /usr/bin/node "./puppeteer-chromium-version-finder.js")
  echo "$CHROMIUM_VERSION"
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || {
    echo "Could not change directory to $DOCKER_CHROMIUM_NOVNC_PATH"
    return 1
  }
  if ! CHROMIUM_VERSION="$CHROMIUM_VERSION" ./script.sh fresh_install; then
    echo "Failed to perform fresh install"
    return 1
  fi
  return 0
}

is_mediawiki_selenium_ready() {
  # are all mediawiki containers up
  if ! are_containers_running "mediawiki-mediawiki-1" "mediawiki-mediawiki-web-1" "mediawiki-mediawiki-jobrunner-1"; then
    return 1
  fi
  # is MW_SERVER value from docker-compose.selenium.yml in use by mediawiki-mediawiki-1 container?
  if ! is_container_env_var_set "mediawiki-mediawiki-1" "MW_SERVER" "http://mediawiki-mediawiki-web-1:8080"; then
    return 1
  fi
  return 0
}

is_docker_chromium_novnc_automation_ready() {
  # are novnc files present?
  if is_dir_empty "$DOCKER_CHROMIUM_NOVNC_PATH"; then
    return 1
  fi
  # is novnc container running?
  if ! is_container_running "docker-chromium-novnc-novnc-1"; then
    return 1
  fi
  # is novnc url available?
  if [ "$(get_response_code http://localhost:8088)" -ne 200 ]; then
    return 1
  fi
  # is chromium container running?
  if ! is_container_running "docker-chromium-novnc-chromium-1"; then
    return 1
  fi
  # is chromium automation ready?
  if ! wait_until_url_available "http://localhost:3111/json/version" 90; then
    echo "Chromium automation not ready"
    return 1
  fi
  return 0
}

ensure_selenium_ready() {
  local start
  start=$(date +%s)

  if ! is_mediawiki_selenium_ready; then
    if ! confirm_action "Mediawiki needs to be prepared for Selenium. This will perform a fresh install. Do you wish to continue"; then
      exit 1
    fi
    echo "Preparing Mediawiki container for Selenium by setting its MW_SERVER env var..."
    if ! prepare_mediawiki_for_selenium; then
      echo "Failed to prepare Mediawiki for Selenium"
      exit 1
    fi
  fi

  if ! is_mediawiki_selenium_ready; then
    echo "Unable to prepare Mediawiki for Selenium"
    exit 1
  fi

  sleep 2

  if ensure_submodule_initialized_and_updated "docker-chromium-novnc" || ! is_docker_chromium_novnc_automation_ready; then
    if ! confirm_action "Chromium / noVNC containers need to be prepared for Selenium. Do you wish to continue"; then
      exit 1
    fi
    echo "Preparing Chromium / noVNC containers for Selenium..."
    if ! prepare_docker_chromium_novnc; then
      echo "Failed to prepare Chromium / noVNC containers for Selenium"
      exit 1
    fi
  fi

  if ! is_docker_chromium_novnc_automation_ready; then
    echo "Unable to prepare Chromium / noVNC containers for Selenium"
    exit 1
  fi

  sleep 2
  connect_network_to_container "docker-chromium-novnc_default" "mediawiki-mediawiki-1"
  connect_network_to_container "docker-chromium-novnc_default" "mediawiki-mediawiki-web-1"

  print_duration_since_start "$start" "ensure_selenium_ready took %d minutes and %d seconds"
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || {
    echo "Could not change directory"
    return 1
  }
  ./script.sh view_novnc
}