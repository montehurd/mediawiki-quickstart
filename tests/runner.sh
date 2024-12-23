#!/bin/bash

current_test=""
test_status=0

handle_test_exit() {
  if [ -n "$current_test" ]; then
    if [ $test_status -eq 0 ]; then
      echo -e "\033[0;32mPASS\033[0m: $current_test"
    else
      echo -e "\033[0;31mFAIL\033[0m: $current_test"
    fi
  fi
}

run_all_tests() {
  local failures=0
  local test_functions
  if [ $# -eq 0 ]; then
    test_functions=$(declare -F | grep ' test_' | cut -d' ' -f3)
  else
    test_functions="$@"
  fi
  for test_func in $test_functions; do
    current_test="$test_func"
    test_status=0
    echo -e "\033[0;34m$test_func\033[0m"
    $test_func
    test_status=$?
    handle_test_exit
    ((failures+=test_status))
    echo
  done
  current_test=""
  echo "Tests completed"
  echo "Total failures: $failures"
  [ $failures -gt 255 ] && failures=255  # Cap at max exit code
  return $failures
}
