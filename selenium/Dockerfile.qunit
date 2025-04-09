FROM node:18-bookworm-slim

ENV FIREFOX_BIN=/usr/bin/firefox-esr

RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends firefox-esr && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html/w

CMD ["npm", "run", "qunit"]