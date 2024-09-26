#!/bin/bash

# set -x

folder="$1"
if [ ! -d "$folder" ]; then
  echo -e "\nImport folder '$folder' not found. Skipping import"
  exit
fi

xml_files=("$folder"/*.xml)
if [ ${#xml_files[@]} -eq 0 ] || [ ! -e "${xml_files[0]}" ]; then
  echo -e "\nNo XML files found in '$folder' - skipping import"
  exit
fi

echo -e "\nImporting pages from '$folder':"
for xml_file in "${xml_files[@]}"; do
  echo -e "\t$(basename "$xml_file")"
  php maintenance/run.php importDump "$xml_file"
done

echo "Import process completed"