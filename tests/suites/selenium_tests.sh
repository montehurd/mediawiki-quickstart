#!/bin/bash

test_login() {
  run_selenium_scenario "should log in"
}

test_version_page_heading() {
  run_selenium_scenario "should show Version heading"
}

run_selenium_scenario() {
  docker cp "./tests/suites/selenium_tests.js" \
    mediawiki-mediawiki-web-1:/var/local/ci.selenium.js 2>&1 | verboseOrDotPerLine ""
  local scenario="$1"
  echo "$scenario"
  ./run_selenium_tests "/var/local/ci.selenium.js" "$scenario" 2>&1 | verboseOrDotPerLine ""
  local run_selenium_tests_status=${PIPESTATUS[0]}
  return "$run_selenium_tests_status"
}
