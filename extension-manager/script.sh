#!/bin/bash

set -eu

if ! [ "$(docker inspect -f '{{.State.Running}}' mediawiki-mediawiki-1)" = "true" ]; then
  echo "MediaWiki container is not running"
  exit 1
fi

docker cp "$(pwd)/isExtensionEnabled.php" mediawiki-mediawiki-1:/var/www/html/w/maintenance/isExtensionEnabled.php

required_keys=('name' 'repository' 'configuration' 'bashScripts')
MEDIAWIKI_PATH="../mediawiki"

yq() {
  echo "$2" | docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq eval "$1" -
}

# Function to validate if all required keys are present in the manifest
validate_keys() {
  local manifest_content=$1
  for key in "${required_keys[@]}"; do
    value=$(yq ".${key}" "$manifest_content")
    # echo "Key $key has value: $value"
    if [ -z "$value" ] || [ "$value" = "null" ]; then
      echo "Missing key $key in manifest, skipping..."
      return 1
    fi
  done
  return 0
}

extension_is_enabled() {
  local extension_name=$1
  local output=$(docker exec -it mediawiki-mediawiki-1 php maintenance/run.php isExtensionEnabled --extension="$extension_name")
  if [ "$output" == "1" ]; then
    return 0
  else
    return 1
  fi
}

# Function to process the manifest and install the extension
process_manifest() {
  local manifest_content=$1
  name=$(yq '.name' "$manifest_content")
  repository=$(yq '.repository' "$manifest_content")
  configuration=$(yq '.configuration' "$manifest_content")
  bashScripts=$(yq '.bashScripts' "$manifest_content")

  # Check if the extension is already installed
  if extension_is_enabled "$name"; then
    echo "Extension $name is already installed and active, skipping..."
    return
  fi

  # Clone the extension
  if ! git clone "$repository" "$MEDIAWIKI_PATH/extensions/$name" --depth=1 2>&1; then
    echo "Failed to clone repository $repository"
    exit 1
  fi

  # Append the configuration to LocalSettings.php with a comment
  echo -e "\n# Configuration for $name extension" >>"$MEDIAWIKI_PATH/LocalSettings.php"
  echo -e "$configuration" >>"$MEDIAWIKI_PATH/LocalSettings.php"

  # Run the bash scripts inside the MediaWiki container
  docker exec mediawiki-mediawiki-1 bash -c "$bashScripts"
}

process_all_manifests() {
  for manifest in ./manifests/*.yaml; do
    # Parse the manifest file once
    manifest_content=$(cat "$manifest")

    # Validate the keys and process the manifest if valid
    if validate_keys "$manifest_content"; then
      process_manifest "$manifest_content"
    else
      echo "Invalid manifest $manifest, skipping..."
    fi
  done
}

process_all_manifests
