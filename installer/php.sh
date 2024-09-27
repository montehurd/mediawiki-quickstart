#!/bin/bash

source "./common/utility.sh"

set -eu

_components_with_composer_json() {
    local components_with_composer=()
    local component=""
    for component in "$@"; do
        if [[ -d "$MEDIAWIKI_PATH/$component" && -f "$MEDIAWIKI_PATH/$component/composer.json" ]]; then
            components_with_composer+=("$component")
        fi
    done
    echo "${components_with_composer[@]}"
}

_build_composer_local_json_for_components() {
    local components=("$@")
    local include_string=""
    local component=""
    for component in "${components[@]}"; do
        include_string+=$'\t\t'"\"$component/composer.json\","$'\n'
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

_restore_composer_local_json() {
    if [[ -f "$MEDIAWIKI_PATH/composer.local.json-sample" ]]; then
        cp "$MEDIAWIKI_PATH/composer.local.json-sample" "$MEDIAWIKI_PATH/composer.local.json"
    fi
}

install_php_dependencies_for_components() {
    local components=("$@")
    local components_with_composer=($(_components_with_composer_json "${components[@]}"))

    if [[ ${#components_with_composer[@]} -eq 0 ]]; then
        echo "No components with PHP dependencies found. Exiting."
        return 0
    fi

    echo -e "\nInstalling PHP dependencies for components: ${components_with_composer[@]}"

    if ! (_build_composer_local_json_for_components "${components_with_composer[@]}"); then
        echo "Failed to build composer.local.json. Exiting."
        _restore_composer_local_json
        return 1
    fi

    sleep 1

    if ! docker exec -it -u root mediawiki-mediawiki-1 sh -c "composer install" 2>&1 | verboseOrDotPerLine "Composer install"; then
        echo "Composer install failed. Exiting."
        _restore_composer_local_json
        return 1
    fi

    if ! docker exec -it -u root mediawiki-mediawiki-1 sh -c "composer update" 2>&1 | verboseOrDotPerLine "Composer update"; then
        echo "Composer update failed. Exiting."
        _restore_composer_local_json
        return 1
    fi

    if ! docker exec -it -u root mediawiki-mediawiki-1 sh -c "php maintenance/run.php update --quick" 2>&1 | verboseOrDotPerLine "PHP maintenance update"; then
        echo "PHP maintenance update failed. Exiting."
        return 1
    fi
    echo

    _restore_composer_local_json
    return 0
}