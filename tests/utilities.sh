#!/bin/bash

run_selenium_scenario() {
  local scenario="$1"
  echo "$scenario"
  ./run_selenium_tests --spec "/var/local/selenium_tests.js" --mochaOpts.grep "$scenario" 2>&1 | verboseOrDotPerLine ""
  local run_selenium_tests_status=${PIPESTATUS[0]}
  return "$run_selenium_tests_status"
}
