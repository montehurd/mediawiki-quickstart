#!/bin/bash

apply_patch () {
  echo "apply patch"
  curl "https://gerrit.wikimedia.org/r/changes/915838/revisions/2/patch?download" | base64 --decode > patch.diff;
  patch -p1 < patch.diff;
}

prepare_node () {
  echo "prepare node"
  curl -sL https://deb.nodesource.com/setup_16.x | bash -;
  apt-get update;
  apt-get install -y nodejs;
  npm install puppeteer-chromium-version-finder;
  npm ci;
  npm audit fix --force;
}

# prepare_chromium () {
#   echo "prepare chromium"
#   VERSION=$(node ./puppeteer-chromium-version-finder.js | tr -d '\r');
#   curl http://docker-chromium-novnc-chromium-1:3111/installChromium/$VERSION;
#   curl http://docker-chromium-novnc-chromium-1:3111/chromiumRestarter;
# }

"$@"