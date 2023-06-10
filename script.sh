#!/bin/bash

# set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "$SCRIPT_DIR/utility.sh"
source "$SCRIPT_DIR/docker-compose-wrapper.sh"

MEDIAWIKI_DIR="$SCRIPT_DIR/mediawiki"
MEDIAWIKI_PORT=8080

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
  mkdir -p "$MEDIAWIKI_DIR"
  cd "$MEDIAWIKI_DIR" || exit
  git clone https://gerrit.wikimedia.org/r/mediawiki/core.git . --depth=1
  echo "$MW_ENV" >.env
  cp "$SCRIPT_DIR/docker-compose.override.yml" .
  if [ -n "$extra_compose_file_path" ] && [ -f "$extra_compose_file_path" ]; then
    cp "$extra_compose_file_path" .
  fi
}

remove() {
  if [ -d "$MEDIAWIKI_DIR" ]; then
    if ! confirm_action "Are you sure you want to delete mediawiki containers and EVERYTHING in \"$MEDIAWIKI_DIR\""; then
      exit 1
    fi
    docker_compose down
    rm -rf "$MEDIAWIKI_DIR"
  fi
}

stop() {
  docker_compose stop
}

start() {
  container_present=$(is_container_present "mediawiki-mediawiki-1")
  is_first_run=$(negate_boolean "$container_present")
  if [ "$is_first_run" = "true" ]; then
    # docker_compose build --no-cache
    docker_compose up -d || exit 1
    docker_compose exec mediawiki composer update
    docker_compose exec mediawiki bash /docker/install.sh
    sleep 2
    use_vector_skin
    return 0
  fi

  is_running=$(is_container_running "mediawiki-mediawiki-1")
  if [ "$is_running" = false ]; then
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
  apply_mediawiki_skin "$MEDIAWIKI_DIR" "Vector" "https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git" "master" "Vector" "vector"
  open_special_version_page
}

use_apiportal_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_DIR" "WikimediaApiPortal" "https://gerrit.wikimedia.org/r/mediawiki/skins/WikimediaApiPortal.git" "master" "WikimediaApiPortal" "wikimediaapiportal"
  open_special_version_page
}

use_minervaneue_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_DIR" "MinervaNeue" "https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue.git" "master" "MinervaNeue" "minerva"
  open_special_version_page
}

use_timeless_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_DIR" "Timeless" "https://gerrit.wikimedia.org/r/mediawiki/skins/Timeless.git" "master" "Timeless" "timeless"
  open_special_version_page
}

use_monobook_skin() {
  apply_mediawiki_skin "$MEDIAWIKI_DIR" "MonoBook" "https://gerrit.wikimedia.org/r/mediawiki/skins/MonoBook.git" "master" "MonoBook" "monobook"
  open_special_version_page
}

open_special_version_page() {
  if [ "${skipopenspecialversionpage:-false}" != "true" ]; then
    open_url_when_available "$SPECIAL_VERSION_URL"
  fi
}

run_parser_tests() {
  docker_compose exec mediawiki php tests/parser/parserTests.php
}

run_php_unit_tests() {
  docker_compose exec --workdir /var/www/html/w/tests/phpunit mediawiki php phpunit.php ${testpath:+$testpath} ${testgroup:+--group $testgroup} --testdox
}

docker_compose() {
  docker_compose_wrapper "$MEDIAWIKI_DIR" "$@"
}

prepare_for_selenium() {
  echo "Preparing for Selenium by adding Node and Chromium / noVNC containers - this usually takes 5 to 10 minutes..."
  export USE_SELENIUM_YML=true
  fresh_install "$SCRIPT_DIR/selenium/docker-compose.selenium.yml"
  docker_compose exec mediawiki ./selenium-preparation.sh apply_patch
  docker_compose exec mediawiki ./selenium-preparation.sh prepare_node
  prepare_docker_chromium_novnc
  wait_until_url_available http://localhost:8088
}

DOCKER_CHROMIUM_NOVNC_PATH="$SCRIPT_DIR/docker-chromium-novnc"

prepare_docker_chromium_novnc() {
  if [ ! -f "$DOCKER_CHROMIUM_NOVNC_PATH/Makefile" ]; then
    git submodule update --init
  fi
  CHROMIUM_VERSION=$(docker_compose exec -u root mediawiki /usr/bin/node "./puppeteer-chromium-version-finder.js")
  echo "$CHROMIUM_VERSION"
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || exit
  CHROMIUM_VERSION="$CHROMIUM_VERSION" ./script.sh fresh_install
}

is_mediawiki_selenium_ready() {
  # are all mediawiki containers up
  if [ "$(are_containers_running "mediawiki-mediawiki-1" "mediawiki-mediawiki-web-1" "mediawiki-mediawiki-jobrunner-1")" != "true" ]; then
    echo "false"
    return
  fi
  # is MW_SERVER value from docker-compose.selenium.yml in use by mediawiki-mediawiki-1 container?
  if [ "$(is_container_env_var_set "mediawiki-mediawiki-1" "MW_SERVER" "http://mediawiki-mediawiki-web-1:8080")" != "true" ]; then
    echo "false"
    return
  fi
  echo "true"
}

is_docker_chromium_novnc_automation_ready() {
  # is novnc container running?
  if [ "$(is_container_running "docker-chromium-novnc-novnc-1")" != "true" ]; then
    echo "false"
    return
  fi
  # is novnc url available?
  if [ "$(get_response_code http://localhost:8088)" -ne 200 ]; then
    echo "false"
    return
  fi
  # is chromium container running?
  cd "$DOCKER_CHROMIUM_NOVNC_PATH" || exit
  if [ "$(is_container_running "docker-chromium-novnc-chromium-1")" != "true" ]; then
    echo "false"
    return
  fi
  # is chromium set for automation?
  if [ "$(docker compose exec chromium curl --write-out '%{http_code}' --silent --output /dev/null localhost:9222 2>/dev/null)" -ne 200 ]; then
    echo "false"
    return
  fi
  echo "true"
}

ensure_selenium_ready() {
  local start
  start=$(date +%s)
  if [ "$(is_docker_chromium_novnc_automation_ready)" = "false" ] || [ "$(is_mediawiki_selenium_ready)" = "false" ]; then
    if ! confirm_action "Mediawiki needs to be reconfigured and Chromium / noVNC containers need to be prepared. This will perform a fresh install. Do you wish to continue"; then
      echo "Exiting as Chromium and noVNC containers were not prepared."
      exit 1
    fi
    prepare_for_selenium
  fi

  print_duration_since_start "$start" "ensure_selenium_ready took %d minutes and %d seconds"
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
