#!/bin/bash

set -eu

install_node_dependencies_for_components() {
    local components=("$@")
    local component=""
    for component in "${components[@]}"; do
        cd ~
        cd "$component"
        /var/local/node-preparation.sh install_node_dependencies 2>&1 | verboseOrDotPerLine "Installing Node dependencies for '$component'"
    done
}