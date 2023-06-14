#!/bin/bash

set -eu

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$SCRIPT_PATH/utility.sh"
source "$SCRIPT_PATH/docker-compose-wrapper.sh"

MEDIAWIKI_PATH="$SCRIPT_PATH/mediawiki"
MEDIAWIKI_PORT=8080

# shellcheck disable=SC2089
MW_ENV="
MW_DOCKER_PORT=$MEDIAWIKI_PORT
MW_DOCKER_UID=
MW_DOCKER_GID=
MEDIAWIKI_USER=Admin
MEDIAWIKI_PASSWORD=dockerpass
XDEBUG_ENABLE=true
XHPROF_ENABLE=true
XDEBUG_CONFIG=''
"

# shellcheck disable=SC2090
export MW_ENV

SPECIAL_VERSION_URL="http://localhost:$MEDIAWIKI_PORT/wiki/Special:Version"

fresh_install() {
  if ! confirm_action "Are you sure you want to do a fresh install"; then
    return
  fi
  local extra_compose_file_path
  extra_compose_file_path=${1:-""}
  stop
  remove
  prepare "$extra_compose_file_path"
  start
}

prepare() {
  local extra_compose_file_path
  extra_compose_file_path=${1:-""}
  mkdir -p "$MEDIAWIKI_PATH"
  cd "$MEDIAWIKI_PATH" || exit
  git clone https://gerrit.wikimedia.org/r/mediawiki/core.git . --depth=1
  echo "$MW_ENV" >.env
  cp "$SCRIPT_PATH/docker-compose.override.yml" . || true
  if [ -n "$extra_compose_file_path" ] && [ -f "$extra_compose_file_path" ]; then
    cp "$extra_compose_file_path" .
  fi
}

remove() {
  if [ ! -d "$MEDIAWIKI_PATH" ]; then
    return
  fi
  if ! confirm_action "Are you sure you want to delete mediawiki containers and EVERYTHING in \"$MEDIAWIKI_PATH\""; then
    exit 1
  fi
  docker_compose down
  if [ -n "$MEDIAWIKI_PATH" ] && [ -d "$MEDIAWIKI_PATH" ]; then
    rm -rf "$MEDIAWIKI_PATH"
  fi
}

stop() {
  if [ ! -d "$MEDIAWIKI_PATH" ]; then
    return
  fi
  docker_compose stop
}

start() {
  if ! is_container_present "mediawiki-mediawiki-1"; then
    # docker_compose build --no-cache
    docker_compose up -d || exit 1
    docker_compose exec mediawiki composer update
    docker_compose exec mediawiki bash /docker/install.sh
    sleep 2
    use_vector_skin
    return 0
  fi

  if ! is_container_running "mediawiki-mediawiki-1"; then
    docker_compose up -d
    sleep 1
  fi
  wait_until_url_available $SPECIAL_VERSION_URL
  open_special_version_page
}

restart() {
  stop
  sleep 2
  start
}

bash_mw() {
  docker_compose exec mediawiki bash
}

bash_jr() {
  docker_compose exec mediawiki-jobrunner bash
}

bash_wb() {
  docker_compose exec mediawiki-web bash
}

use_vector_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_PATH" "Vector" "https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git" "master" "Vector" "vector"
  open_special_version_page
}

use_apiportal_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_PATH" "WikimediaApiPortal" "https://gerrit.wikimedia.org/r/mediawiki/skins/WikimediaApiPortal.git" "master" "WikimediaApiPortal" "wikimediaapiportal"
  open_special_version_page
}

use_minervaneue_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_PATH" "MinervaNeue" "https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue.git" "master" "MinervaNeue" "minerva"
  open_special_version_page
}

use_timeless_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_PATH" "Timeless" "https://gerrit.wikimedia.org/r/mediawiki/skins/Timeless.git" "master" "Timeless" "timeless"
  open_special_version_page
}

use_monobook_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_PATH" "MonoBook" "https://gerrit.wikimedia.org/r/mediawiki/skins/MonoBook.git" "master" "MonoBook" "monobook"
  open_special_version_page
}

open_special_version_page() {
  if [ "${skipopenspecialversionpage:-false}" = "true" ]; then
    return
  fi
  open_url_when_available "$SPECIAL_VERSION_URL"
}

run_parser_tests() {
  docker_compose exec mediawiki php tests/parser/parserTests.php
}

run_php_unit_tests() {
  docker_compose exec --workdir /var/www/html/w/tests/phpunit mediawiki php phpunit.php ${testpath:+$testpath} ${testgroup:+--group $testgroup} --testdox
}

docker_compose() {
  docker_compose_wrapper "$MEDIAWIKI_PATH" "$@"
}

prepare_mediawiki_for_selenium() {
  echo "Preparing Mediawiki container for Selenium by adding Node and setting its MW_SERVER env var..."
  export USE_SELENIUM_YML=true
  fresh_install "$SCRIPT_PATH/selenium/docker-compose.selenium.yml"
  docker_compose exec mediawiki ./selenium-preparation.sh apply_patch
  docker_compose exec mediawiki ./selenium-preparation.sh prepare_node
}

DOCKER_CHROMIUM_NOVNC_PATH="$SCRIPT_PATH/docker-chromium-novnc"

prepare_docker_chromium_novnc() {
  echo "Preparing Chromium / noVNC containers for Selenium..."
  if [ ! -f "$DOCKER_CHROMIUM_NOVNC_PATH/Makefile" ]; then
    cd "$SCRIPT_PATH" || { echo "Could not change directory"; return 1; }
    git submodule update --init
    sleep 1
  fi
  CHROMIUM_VERSION=$(docker_compose exec -u root mediawiki /usr/bin/node "./puppeteer-chromium-version-finder.js")
  echo "$CHROMIUM_VERSION"
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || { echo "Could not change directory"; return 1; }
  CHROMIUM_VERSION="$CHROMIUM_VERSION" ./script.sh fresh_install
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
  # is chromium set for automation?
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || { echo "Could not change directory"; return 1; }
  if [ "$(docker compose exec chromium curl --write-out '%{http_code}' --silent --output /dev/null localhost:9222 2>/dev/null)" -ne 200 ]; then
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
    prepare_mediawiki_for_selenium
  fi
  if ! is_docker_chromium_novnc_automation_ready; then
    if ! confirm_action "Chromium / noVNC containers need to be prepared. Do you wish to continue"; then
      exit 1
    fi
    prepare_docker_chromium_novnc
  fi
  print_duration_since_start "$start" "ensure_selenium_ready took %d minutes and %d seconds"
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || { echo "Could not change directory"; return 1; }
  ./script.sh view_novnc
}

run_selenium_tests() {
  ensure_selenium_ready
  docker_compose exec mediawiki npx wdio /var/www/html/w/tests/selenium/wdio.conf.override.js
}

run_selenium_test_file() {
  ensure_selenium_ready
  docker_compose exec mediawiki npx wdio /var/www/html/w/tests/selenium/wdio.conf.override.js --spec /var/www/html/w/tests/selenium/specs/user.js
}

run_selenium_test_wildcard() {
  ensure_selenium_ready
  docker_compose exec mediawiki npx wdio /var/www/html/w/tests/selenium/wdio.conf.override.js --spec /var/www/html/w/tests/selenium/specs/**/*.js
}

run_selenium_test() {
  ensure_selenium_ready
  docker_compose exec mediawiki npx wdio /var/www/html/w/tests/selenium/wdio.conf.override.js --spec /var/www/html/w/tests/selenium/specs/page.js --logLevel debug --mochaOpts.grep 'should be creatable'
}

"$@"
