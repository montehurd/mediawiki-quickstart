#!/bin/bash

test_shellto_mediawiki() {
  output=$(SILENT=1 ./shellto m pwd 2>&1)
  if ! echo "$output" | grep -q "/var/www/html/w"; then
    echo "Wrong path in mediawiki container"
    return 1
  fi
  echo "Correct path found in mediawiki container"
  return 0
}

test_shellto_mediawiki_interactive() {
  output=$(echo -e "pwd\nexit" | SILENT=1 ./shellto m 2>&1)
  if ! echo "$output" | grep -q "/var/www/html/w"; then
    echo "Interactive shell did not show correct path"
    return 1
  fi
  echo "Interactive shell worked as expected"
  return 0
}

test_shellto_web() {
  output=$(SILENT=1 ./shellto w pwd 2>&1)
  if ! echo "$output" | grep -q "/var/www/html/w"; then
    echo "Wrong path in web container"
    return 1
  fi
  echo "Correct path found in web container"
  return 0
}

test_shellto_web_interactive() {
  output=$(echo -e "pwd\nexit" | SILENT=1 ./shellto w 2>&1)
  if ! echo "$output" | grep -q "/var/www/html/w"; then
    echo "Interactive shell did not show correct path"
    return 1
  fi
  echo "Interactive shell worked as expected"
  return 0
}

test_shellto_jobrunner() {
  output=$(SILENT=1 ./shellto j pwd 2>&1)
  if ! echo "$output" | grep -q "/var/www/html/w"; then
    echo "Wrong path in jobrunner container"
    return 1
  fi
  echo "Correct path found in jobrunner container"
  return 0
}

test_shellto_jobrunner_interactive() {
  output=$(echo -e "pwd\nexit" | SILENT=1 ./shellto j 2>&1)
  if ! echo "$output" | grep -q "/var/www/html/w"; then
    echo "Interactive shell did not show correct path"
    return 1
  fi
  echo "Interactive shell worked as expected"
  return 0
}

test_shellto_novnc() {
  output=$(SILENT=1 ./shellto n pwd 2>&1)
  if ! echo "$output" | grep -q "/"; then
    echo "Wrong path in novnc container"
    return 1
  fi
  echo "Correct path found in novnc container"
  return 0
}

test_shellto_novnc_interactive() {
  output=$(echo -e "pwd\nexit" | SILENT=1 ./shellto n 2>&1)
  if ! echo "$output" | grep -q "/"; then
    echo "Interactive shell did not show correct path"
    return 1
  fi
  echo "Interactive shell worked as expected"
  return 0
}
