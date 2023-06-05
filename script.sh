#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
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
  if ! "$SCRIPT_DIR/utility.sh" confirm_action "Are you sure you want to do a fresh install"; then
    return
  fi
  local extra_compose_file_path=${1:-""}
  stop
  remove
  prepare "$extra_compose_file_path"
  start
}

prepare() {
  local extra_compose_file_path=${1:-""}
  mkdir -p "$MEDIAWIKI_DIR"
  cd "$MEDIAWIKI_DIR"
  git clone https://gerrit.wikimedia.org/r/mediawiki/core.git . --depth=1
  echo "$MW_ENV" >.env
  cp "$SCRIPT_DIR/docker-compose.override.yml" .
  if [ -n "$extra_compose_file_path" ] && [ -f "$extra_compose_file_path" ]; then
    cp "$extra_compose_file_path" .
  fi
}

remove() {
  if [ -d "$MEDIAWIKI_DIR" ]; then
    if ! "$SCRIPT_DIR/utility.sh" confirm_action "Are you sure you want to delete mediawiki containers and EVERYTHING in \"$MEDIAWIKI_DIR\""; then
      exit 1
    fi
    docker_compose down
    rm -rf "$MEDIAWIKI_DIR"
    rm -f "$SCRIPT_DIR/runonce"
  fi
}

stop() {
  docker_compose stop
}

start() {
  if [ ! -f "$SCRIPT_DIR/runonce" ]; then
    docker_compose up -d
    docker_compose exec mediawiki composer update
    docker_compose exec mediawiki bash /docker/install.sh
    sleep 2
    touch "$SCRIPT_DIR/runonce"
    use_vector_skin
    return 0
  fi

  is_running=$("$SCRIPT_DIR/utility.sh" is_container_running "mediawiki-mediawiki-1")
  if [ "$is_running" = false ]; then
    docker_compose up -d
    sleep 1
  fi

  "$SCRIPT_DIR/utility.sh" wait_until_url_available $SPECIAL_VERSION_URL
  open_special_version_page
}

restart() {
  stop
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
  set -k
  "$SCRIPT_DIR/utility.sh" apply_mediawiki_skin mediawikiPath=$MEDIAWIKI_DIR skinSubdirectory=Vector skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git skinBranch=master wfLoadSkin=Vector wgDefaultSkin=vector
  open_special_version_page
}

use_apiportal_skin() {
  set -k
  "$SCRIPT_DIR/utility.sh" apply_mediawiki_skin mediawikiPath=$MEDIAWIKI_DIR skinSubdirectory=WikimediaApiPortal skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/WikimediaApiPortal.git skinBranch=master wfLoadSkin=WikimediaApiPortal wgDefaultSkin=WikimediaApiPortal
  open_special_version_page
}

use_minervaneue_skin() {
  set -k
  "$SCRIPT_DIR/utility.sh" apply_mediawiki_skin mediawikiPath=$MEDIAWIKI_DIR skinSubdirectory=MinervaNeue skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue.git skinBranch=master wfLoadSkin=MinervaNeue wgDefaultSkin=minerva
  open_special_version_page
}

use_timeless_skin() {
  set -k
  "$SCRIPT_DIR/utility.sh" apply_mediawiki_skin mediawikiPath=$MEDIAWIKI_DIR skinSubdirectory=Timeless skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Timeless.git skinBranch=master wfLoadSkin=Timeless wgDefaultSkin=timeless
  open_special_version_page
}

use_monobook_skin() {
  set -k
  "$SCRIPT_DIR/utility.sh" apply_mediawiki_skin mediawikiPath=$MEDIAWIKI_DIR skinSubdirectory=MonoBook skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/MonoBook.git skinBranch=master wfLoadSkin=MonoBook wgDefaultSkin=monobook
  open_special_version_page
}

open_special_version_page() {
  if [ "$skipopenspecialversionpage" != "true" ]; then
    "$SCRIPT_DIR/utility.sh" open_url_when_available $SPECIAL_VERSION_URL
  fi
}

run_parser_tests() {
  docker_compose exec mediawiki php tests/parser/parserTests.php
}

run_php_unit_tests() {
  docker_compose exec --workdir /var/www/html/w/tests/phpunit mediawiki php phpunit.php ${testpath:+$testpath} ${testgroup:+--group $testgroup} --testdox
}

docker_compose() {
  "$SCRIPT_DIR/docker-compose-wrapper.sh" "$MEDIAWIKI_DIR" "$@"
}

prepare_selenium() {
  echo "Preparing Selenium - this may take a few minutes..."
  export USE_SELENIUM_YML=true
  fresh_install "$SCRIPT_DIR/selenium/docker-compose.selenium.yml"
  docker_compose exec mediawiki ./selenium-preparation.sh apply_patch
  docker_compose exec mediawiki ./selenium-preparation.sh prepare_node
  prepare_chromium
  "$SCRIPT_DIR/utility.sh" wait_until_url_available http://localhost:8088
}

CHROMIUM_DIR="$SCRIPT_DIR/docker-chromium-novnc"

prepare_chromium() {
  if [ ! -f "$CHROMIUM_DIR/Makefile" ]; then
    git submodule update --init
  fi
  CHROMIUM_VERSION=$(docker_compose exec -u root mediawiki /usr/bin/node "./puppeteer-chromium-version-finder.js")
  echo "$CHROMIUM_VERSION"
  cd "$CHROMIUM_DIR"
  CHROMIUM_VERSION="$CHROMIUM_VERSION" ./script.sh fresh_install
}

is_selenium_prepared() {
  # is novnc container running?
  if [ "$("$SCRIPT_DIR/utility.sh" is_container_running "docker-chromium-novnc-novnc-1")" != "true" ]; then
    echo "false"
    return
  fi
  # is novnc url available?
  if [ $("$SCRIPT_DIR/utility.sh" get_response_code http://localhost:8088) -ne 200 ]; then
    echo "false"
    return
  fi
  # is chromium container running?
  cd "$CHROMIUM_DIR"
  if [ "$("$SCRIPT_DIR/utility.sh" is_container_running "docker-chromium-novnc-chromium-1")" != "true" ]; then
    echo "false"
    return
  fi
  # is chromium set for automation?
  if [ $(docker compose exec chromium curl --write-out '%{http_code}' --silent --output /dev/null localhost:9222 2>/dev/null) -ne 200 ]; then
    echo "false"
    return
  fi
  echo "true"
}

ensure_selenium_ready() {
  if [ "$(is_selenium_prepared)" = false ]; then
    if ! "$SCRIPT_DIR/utility.sh" confirm_action "Selenium containers need to be prepared. This will perform a fresh install. Do you wish to continue"; then
      echo "Exiting as Selenium containers were not prepared."
      exit 1
    fi
    prepare_selenium
  fi
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
