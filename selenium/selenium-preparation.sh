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

# prepare_chromium () {
#   echo "prepare chromium"
#   VERSION=$(node ./puppeteer-chromium-version-finder.js | tr -d '\r');
#   curl http://docker-chromium-novnc-chromium-1:3111/installChromium/$VERSION;
#   curl http://docker-chromium-novnc-chromium-1:3111/chromiumRestarter;
# }

"$@"
