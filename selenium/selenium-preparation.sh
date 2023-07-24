#!/bin/bash

set -eu

apply_patch() {
  echo "apply patch"
  if ! curl --retry 10 --retry-delay 10 -f "https://gerrit.wikimedia.org/r/changes/915838/revisions/4/patch?download" | base64 --decode >patch.diff; then
    echo "Failed to download patch"
    return 1
  fi
  if patch --dry-run -p1 -N <patch.diff; then
    if ! patch -p1 -N <patch.diff; then
      return 1
    fi
  else
    echo "Patch has already been applied or cannot be applied."
    return 1
  fi
  return 0
}

prepare_node() {
  echo "prepare node"
  if ! command -v node >/dev/null; then
    if ! curl --retry 10 --retry-delay 10 -sL https://deb.nodesource.com/setup_16.x | bash -; then
      echo "Failed to fetch node setup bits"
      return 1
    fi
    if ! apt-get update; then
      echo "Failed to update package list"
      return 1
    fi
    if ! apt-get install -y nodejs; then
      echo "Failed to install nodejs"
      return 1
    fi
    if ! npm install puppeteer-chromium-version-finder; then
      echo "Failed to install puppeteer-chromium-version-finder"
      return 1
    fi
    if ! npm ci; then
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
