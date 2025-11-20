#!/bin/bash

source "/var/local/common/utility.sh"

import_page_xml() {
  local imported=false

  for folder in "$@"; do
    if [ ! -d "$folder" ]; then
      echo "Import folder '$folder' not found, skipping..."
      continue
    fi

    xml_files=("$folder"/*.xml)
    if [ ${#xml_files[@]} -eq 0 ] || [ ! -e "${xml_files[0]}" ]; then
      echo "No XML files found in '$folder', skipping..."
      continue
    fi

    for xml_file in "${xml_files[@]}"; do
      echo "php importDump for '$(basename "$xml_file")'"
      php maintenance/run.php importDump "$xml_file"
      imported=true
    done
  done

  if [ "$imported" = true ]; then
    echo -e "\nphp rebuildrecentchanges"
    php maintenance/run.php rebuildrecentchanges
    echo -e "\nphp initSiteStats --update"
    php maintenance/run.php initSiteStats --update
  else
    echo "No pages were imported"
  fi

  echo "Page import process completed"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  import_page_xml "$@" 2>&1 | verboseOrDotPerLine "Importing pages from '$@', if found"
fi
