#!/bin/bash

apply_patch() {
  echo "apply patch"
  curl "https://gerrit.wikimedia.org/r/changes/915838/revisions/2/patch?download" | base64 --decode >patch.diff
  if patch --dry-run -p1 -N <patch.diff; then
    patch -p1 -N <patch.diff
  else
    echo "Patch has already been applied or cannot be applied."
  fi
}

prepare_node() {
  echo "prepare node"
  if ! command -v node > /dev/null; then
    curl -sL https://deb.nodesource.com/setup_16.x | bash -
    apt-get update
    apt-get install -y nodejs
    npm install puppeteer-chromium-version-finder
    npm ci
    npm audit fix --force
  fi
}

# prepare_chromium () {
#   echo "prepare chromium"
#   VERSION=$(node ./puppeteer-chromium-version-finder.js | tr -d '\r');
#   curl http://docker-chromium-novnc-chromium-1:3111/installChromium/$VERSION;
#   curl http://docker-chromium-novnc-chromium-1:3111/chromiumRestarter;
# }

"$@"
