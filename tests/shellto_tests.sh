#!/bin/bash

# Get the command that would ultimately be executed (without executing it)
# Lets us not worry about ultimately inconsequential quoting differences,
# what's important is what ultimately gets executed
get_ultimate_command() {
  # Process the command into an array using eval
  eval "set -- $1"
  # Reconstruct the command without quotes
  printf '%s ' "$@"
}

verify_shellto_command() {
  local expected
  local command
  read -r expected
  read -r command
  local output=$(eval "SHELLTO_TEST=1 $command" 2>/dev/null) # Run command as passed
  local ultimate_expected=$(get_ultimate_command "$expected")
  echo "Expected:"
  echo -e "\t$ultimate_expected"
  local ultimate_output=$(get_ultimate_command "$output")
  echo "Actual:"
  echo -e "\t$ultimate_output"
  if [ "$ultimate_expected" = "$ultimate_output" ]; then
    return 0
  fi
  return 1
}

test_shellto_single_env_with_path() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" -e DISPLAY=mediawiki-novnc-1:0 mediawiki-web /var/local/install-browser-for-puppeteer-core.sh
  ./shellto -e DISPLAY=mediawiki-novnc-1:0 w /var/local/install-browser-for-puppeteer-core.sh
EOF
}

test_shellto_multiple_env_with_paths() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" -e VERBOSE -e GIT_CLONE_BASE_URL -e BRANCH -e SKIP_LOCALIZATION_CACHE_REBUILD -e SKIP_PAGE_IMPORT mediawiki /var/local/installer/install extensions/IPInfo skins/MonoBook
  ./shellto -e VERBOSE -e GIT_CLONE_BASE_URL m /var/local/installer/install extensions/IPInfo skins/MonoBook
EOF
}

test_shellto_sh_c_with_env_var() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki-web sh -c "FIREFOX_BIN=/usr/bin/firefox-esr npm run qunit"
  ./shellto w sh -c "FIREFOX_BIN=/usr/bin/firefox-esr npm run qunit"
EOF
}

test_shellto_argument_separator() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki composer phpunit -- --testdox --group Cache
  ./shellto m composer phpunit -- --testdox --group Cache
EOF
}

test_shellto_relative_dot_path() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki-web find . -user root
  ./shellto w find . -user root
EOF
}

test_shellto_user_override() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" -u root mediawiki-web chown -R "123:456" /var/local
  ./shellto -u root w chown -R "123:456" /var/local
EOF
}

test_shellto_basic_command() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki composer install
  ./shellto m composer install
EOF
}

test_shellto_docker_path() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki /docker/install.sh
  ./shellto m /docker/install.sh
EOF
}

test_shellto_path_with_args() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki /var/local/node-preparation.sh install_node_dependencies
  ./shellto m /var/local/node-preparation.sh install_node_dependencies
EOF
}

test_shellto_env_with_quoted_path() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" -e VERBOSE mediawiki /import_page_xml.sh "/tmp/page-xml"
  ./shellto -e VERBOSE m /import_page_xml.sh "/tmp/page-xml"
EOF
}

test_shellto_relative_subdir_path() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki php tests/parser/parserTests.php
  ./shellto m php tests/parser/parserTests.php
EOF
}

test_shellto_command_with_subcommand() {
  verify_shellto_command << EOF
  docker compose exec -u "$(id -u):$(id -g)" mediawiki-web npm run jest
  ./shellto w npm run jest
EOF
}