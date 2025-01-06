#!/bin/bash

source "./tests/utilities.sh"

test_login() {
  run_selenium_scenario "should log in"
}

test_version_page_heading() {
  run_selenium_scenario "should show Version heading"
}