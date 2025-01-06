#!/bin/bash

source "./tests/utilities.sh"

test_install_skin() {
  SILENT=1 ./install skins/MonoBook 2>&1 | verboseOrDotPerLine ""
  if [ ! -d "./mediawiki/skins/MonoBook" ]; then
    echo "MonoBook skin directory not created"
    return 1
  fi
  echo "Monobook skin directory present as expected"
  return 0
}

test_make_skin_default() {
  SILENT=1 ./make_skin_default MonoBook 2>&1 | verboseOrDotPerLine ""
  if ! curl -s -f -o /dev/null --retry 4 --retry-delay 2 --retry-max-time 15 -w "%{http_code}" "http://localhost:8080/wiki/Special:Version" | grep -q "200"; then
    echo "Special:Version page not responding with 200"
    return 1
  fi
  echo "Special:Version page still accessible as expected"
  run_selenium_scenario "(should log in|appearance settings should have selected monobook radio button)"
}

test_use_skin() {
  SILENT=1 ./use_skin Timeless 2>&1 | verboseOrDotPerLine ""
  if [ ! -d "./mediawiki/skins/Timeless" ]; then
    echo "Timeless skin directory not created"
    return 1
  fi
  echo "Timeless skin directory present as expected"
  return 0
}

test_vector_skin_was_cloned() {
  if [ ! -d "./mediawiki/skins/Vector" ]; then
    echo "Vector skin directory not created"
    return 1
  fi
  echo "Vector skin directory present as expected"
  return 0
}

test_vector_skin_appearance_setting() {
  SILENT=1 ./make_skin_default Vector 2>&1 | verboseOrDotPerLine ""
  run_selenium_scenario "(should log in|appearance settings should have selected vector radio button)"
}

was_skin_cloned() {
  if [ ! -d "./mediawiki/skins/$1" ]; then
    echo "$1 skin directory not created"
    return 1
  fi
  echo "$1 skin directory present as expected"
  return 0
}
