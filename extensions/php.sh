#!/bin/bash

set -eu

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
MEDIAWIKI_PATH="$SCRIPT_PATH/../mediawiki"
EXTENSIONS_PATH="$MEDIAWIKI_PATH/extensions"

_extensions_with_composer_json() {
    local extensions_with_composer=()
    local extension=""
    for extension in "$@"; do
        if [[ -d "$EXTENSIONS_PATH/$extension" && -f "$EXTENSIONS_PATH/$extension/composer.json" ]]; then
            extensions_with_composer+=("$extension")
        fi
    done
    echo "${extensions_with_composer[@]}"
}

_build_composer_local_json_for_extensions() {
    local extensions=("$@")
    local include_string=""
    local extension=""
    for extension in "${extensions[@]}"; do
        include_string+=$'\t\t'"\"extensions/$extension/composer.json\","$'\n'
    done
    include_string="${include_string%,$'\n'}"
    cat > "$MEDIAWIKI_PATH/composer.local.json" <<- EOM
{
    "extra": {
        "merge-plugin": {
            "include": [
$include_string
            ]
        }
    }
}
EOM
    return 0
}

_backup_composer_local_json() {
    if [[ -f "$MEDIAWIKI_PATH/composer.local.json" ]]; then
        cp "$MEDIAWIKI_PATH/composer.local.json" "$MEDIAWIKI_PATH/composer.local.json.copy"
    fi
}

_restore_composer_local_json() {
    if [[ -f "$MEDIAWIKI_PATH/composer.local.json.copy" ]]; then
        mv "$MEDIAWIKI_PATH/composer.local.json.copy" "$MEDIAWIKI_PATH/composer.local.json"
    fi
}

# Backs up composer.local.json
# Generates new composer.local.json with entries for our extensions 
# Installs php dependencies for our extensions
# Restores backed up composer.local.json
install_php_dependencies_for_extensions() {
    local extensions=("$@")
    local extensions_with_composer=($(_extensions_with_composer_json "${extensions[@]}"))

    if [[ ${#extensions_with_composer[@]} -eq 0 ]]; then
        echo "No extensions with php dependencies found. Exiting."
        return 0
    fi

    echo "Installing php dependencies for extensions: ${extensions_with_composer[@]}"

    _backup_composer_local_json

    if ! (_build_composer_local_json_for_extensions "${extensions_with_composer[@]}"); then
        echo "Failed to build composer.local.json. Exiting."
        _restore_composer_local_json
        return 1
    fi

    sleep 1

    if ! docker exec -it -u root mediawiki-mediawiki-1 sh -c "composer install" > /dev/null 2>&1; then
        echo "Composer install failed. Exiting."
        _restore_composer_local_json
        return 1
    fi

    _restore_composer_local_json
    return 0
}
