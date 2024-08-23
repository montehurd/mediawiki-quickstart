#!/bin/bash

set -eu

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
MEDIAWIKI_PATH="$SCRIPT_PATH/../mediawiki"
EXTENSIONS_PATH="$MEDIAWIKI_PATH/extensions"

_extensions_with_file() {
    local file_name="$1"
    shift
    local extensions=("$@")
    local valid_extensions=()
    for extension in "${extensions[@]}"; do
        if [[ -f "$EXTENSIONS_PATH/$extension/$file_name" ]]; then
            valid_extensions+=("$extension")
        fi
    done
    echo "${valid_extensions[@]}"
}

install_node_dependencies_for_extensions() {
    local extensions=("$@")

    local extensions_with_package_lock_json=($(_extensions_with_file "package-lock.json" "${extensions[@]}"))
    local extensions_with_package_json=($(_extensions_with_file "package.json" "${extensions[@]}"))
    
    if [[ ${#extensions_with_package_lock_json[@]} -eq 0 ]] && [[ ${#extensions_with_package_json[@]} -eq 0 ]]; then
        echo "No extensions with package-lock.json or package.json found. Exiting."
        return 0
    fi
    
    SECONDS=0

    if [[ ${#extensions_with_package_lock_json[@]} -gt 0 ]]; then
        echo -e "\nInstalling Node dependencies for extensions with package-lock.json: ${extensions_with_package_lock_json[@]}"
        docker exec -it -u root mediawiki-mediawiki-web-1 bash -c '
            printf "./extensions/%s\n" "$@" | xargs -I {} sh -c "cd {} && echo \"Installing Node dependencies for \$(pwd) using npm ci\" && npm ci > ./npm_ci.log 2>&1"
        ' _ "${extensions_with_package_lock_json[@]}"
    fi
    
    # Remove extensions with package-lock.json from extensions_with_package_json
    # ie only do a "npm install" if we haven't already done a "npm ci"
    for ext in "${extensions_with_package_lock_json[@]}"; do
        extensions_with_package_json=(${extensions_with_package_json[@]/$ext})
    done

    if [[ ${#extensions_with_package_json[@]} -gt 0 ]]; then
        echo -e "Installing Node dependencies for extensions with only package.json: ${extensions_with_package_json[@]}"
        docker exec -it -u root mediawiki-mediawiki-web-1 bash -c '
            printf "./extensions/%s\n" "$@" | xargs -I {} sh -c "cd {} && echo \"Installing Node dependencies for \$(pwd) using npm install\" && npm install > ./npm_install.log 2>&1"
        ' _ "${extensions_with_package_json[@]}"
    fi

    ELAPSED=$SECONDS
    echo "Duration for node dependency installation: $((ELAPSED/60)) minutes $((ELAPSED%60)) seconds"
}