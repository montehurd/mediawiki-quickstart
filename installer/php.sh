#!/bin/bash

source "./common/utility.sh"

set -eu

install_php_dependencies_for_components() {
    ./shellto m cp composer.local.json-sample composer.local.json

    if ! { ./shellto m composer update 2>&1 | verboseOrDotPerLine "Composer update"; }; then
        echo "Composer update failed. Exiting."
        return 1
    fi

    if ! { ./shellto m composer install 2>&1 | verboseOrDotPerLine "Composer install"; }; then
        echo "Composer install failed. Exiting."
        return 1
    fi

    if ! { ./shellto m php maintenance/run.php update --quick 2>&1 | verboseOrDotPerLine "PHP maintenance update"; }; then
        echo "PHP maintenance update failed. Exiting."
        return 1
    fi

    return 0
}