#!/bin/bash

set -e
cd /var/www/html/w
CHROME_PATH=$(node -e "
  require('dotenv').config();
  console.log(process.env.CHROME_PATH || '');
")
if [ -z "$CHROME_PATH" ]; then
  echo "Installing Selenium browser binary..."
  CHROME_PATH=$(node /var/local/install-browser-for-puppeteer-core.js) || {
    echo "Error: Browser installation failed" >&2
    exit 1
  }
  echo "CHROME_PATH=$CHROME_PATH" >> .env
fi
"$CHROME_PATH" --version || {
  echo "Error: Chrome binary not found or not executable at $CHROME_PATH" >&2
  exit 1
}