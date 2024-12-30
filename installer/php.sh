#!/bin/bash

source "/var/local/common/utility.sh"

set -eu

install_php_dependencies_for_components() {
    if ! cp composer.local.json-sample composer.local.json 2>&1 | verboseOrDotPerLine "Copying 'composer.local.json-sample' to 'composer.local.json'"; then
        echo "Failed to copy composer.local.json-sample. Exiting."
        return 1
    fi

    if ! composer update 2>&1 | verboseOrDotPerLine "Composer update"; then
        echo "Composer update failed. Exiting."
        return 1
    fi

    if ! composer install 2>&1 | verboseOrDotPerLine "Composer install"; then
        echo "Composer install failed. Exiting."
        return 1
    fi

    if ! php maintenance/run.php update --quick 2>&1 | verboseOrDotPerLine "PHP maintenance update"; then
        echo "PHP maintenance update failed. Exiting."
        return 1
    fi

    return 0
}