#!/bin/bash

# Reminder: the path on the next line is in the container
source "/shell-utilities/utilities.sh"

# set -x

import_page_xml() {
    local imported=false

    for folder in "$@"; do
        if [ ! -d "$folder" ]; then
            echo -e "\nImport folder '$folder' not found, skipping..."
            continue
        fi

        xml_files=("$folder"/*.xml)
        if [ ${#xml_files[@]} -eq 0 ] || [ ! -e "${xml_files[0]}" ]; then
            echo -e "\nNo XML files found in '$folder', skipping..."
            continue
        fi

        echo -e "\nImporting pages from '$folder':"
        for xml_file in "${xml_files[@]}"; do
            php maintenance/run.php importDump "$xml_file" 2>&1 | verboseOrDotPerLine "php importDump for $(basename "$xml_file")"
            imported=true
        done
    done

    if [ "$imported" = true ]; then
        php maintenance/run.php rebuildrecentchanges 2>&1 | verboseOrDotPerLine "php rebuildrecentchanges"
        php maintenance/run.php initSiteStats --update 2>&1 | verboseOrDotPerLine "php initSiteStats --update"
    else
        echo "No pages were imported"
    fi

    echo "Page import process completed"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    import_page_xml "$@"
fi