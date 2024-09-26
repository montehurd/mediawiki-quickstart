#!/bin/bash

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
            echo -e "\t$(basename "$xml_file")"
            php maintenance/run.php importDump "$xml_file"
            imported=true
        done
    done

    if [ "$imported" = true ]; then
        echo -e "\nUpdating recent changes:"
        php maintenance/run.php rebuildrecentchanges
        echo -e "\nUpdating site stats:"
        php maintenance/run.php initSiteStats --update
    else
        echo "No pages were imported"
    fi

    echo "Page import process completed"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    import_page_xml "$@"
fi