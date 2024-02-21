#!/bin/bash

set -eu

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
MEDIAWIKI_PATH="$SCRIPT_PATH/../mediawiki"
EXTENSIONS_PATH="$MEDIAWIKI_PATH/extensions"

_extensions_with_package_json() {
    local extensions=("$@")
    local valid_extensions=()
    for extension in "${extensions[@]}"; do
        if [[ -f "$EXTENSIONS_PATH/$extension/package.json" ]]; then
            valid_extensions+=("$extension")
        fi
    done
    echo "${valid_extensions[@]}"
}

install_node_dependencies_for_extensions() {
    local extensions=($(_extensions_with_package_json "$@"))
    if [[ ${#extensions[@]} -eq 0 ]]; then
        echo "No extensions with package.json found. Exiting."
        return 0
    fi
    echo -e "\nInstalling node dependencies for extensions: ${extensions[@]}"
    docker exec -it -u root mediawiki-mediawiki-1 bash -c '
        SECONDS=0
        printf "./extensions/%s\\n" "$@" | xargs -I {} -P 2 sh -c "cd {} && echo \"Installing Node dependencies for \$(pwd)\" && npm install > ./npm_install.log 2>&1"
        ELAPSED=$SECONDS
        echo "Duration: "$((ELAPSED/60))" minutes "$((ELAPSED%60))" seconds"
    ' _ "${extensions[@]}"
    return $?
}