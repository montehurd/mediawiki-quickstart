#!/bin/bash

set -eu

apply_patch() {
  echo "apply patch"
  curl -f "https://gerrit.wikimedia.org/r/changes/915838/revisions/4/patch?download" | base64 --decode >patch.diff
  if [ $? -ne 0 ]; then
    echo "Failed to download patch"
    return 1
  fi
  if patch --dry-run -p1 -N <patch.diff; then
    patch -p1 -N <patch.diff && return 0 || return 1
  else
    echo "Patch has already been applied or cannot be applied."
    return 1
  fi
}

prepare_node() {
  echo "prepare node"
  if ! command -v node > /dev/null; then
    curl -sL https://deb.nodesource.com/setup_16.x | bash -
    apt-get update && apt-get install -y nodejs
    if [ $? -ne 0 ]; then
      echo "Failed to install nodejs"
      return 1
    fi
    npm install puppeteer-chromium-version-finder
    if [ $? -ne 0 ]; then
      echo "Failed to install puppeteer-chromium-version-finder"
      return 1
    fi
    npm ci
    if [ $? -ne 0 ]; then
      echo "Failed to install node packages"
      return 1
    fi
  fi
  return 0
}

# prepare_chromium () {
#   echo "prepare chromium"
#   VERSION=$(node ./puppeteer-chromium-version-finder.js | tr -d '\r');
#   curl http://docker-chromium-novnc-chromium-1:3111/installChromium/$VERSION;
#   curl http://docker-chromium-novnc-chromium-1:3111/chromiumRestarter;
# }

"$@"
