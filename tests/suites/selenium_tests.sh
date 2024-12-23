#!/bin/bash

test_login() {
  run_selenium_scenario "should log in"
}

test_version_page_heading() {
  run_selenium_scenario "should show Version heading"
}

run_selenium_scenario() {
  docker cp "./ci.selenium.js" \
    mediawiki-mediawiki-web-1:/var/www/html/w/tests/selenium/ci.selenium.js 2>&1 | verboseOrDotPerLine ""
  local scenario="$1"
  echo "$scenario"
  ./run_selenium_tests "tests/selenium/ci.selenium.js" "$scenario" 2>&1 | verboseOrDotPerLine ""
  local run_selenium_tests_status=${PIPESTATUS[0]}
  return "$run_selenium_tests_status"
}
