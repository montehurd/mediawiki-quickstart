#!/bin/bash

# Install DjVu tools and netpbm (for pnmtojpeg) needed by ProofreadPage tests
apt-get update -qq && apt-get install -y -qq djvulibre-bin netpbm 2>/dev/null
