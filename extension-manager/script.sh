#!/bin/bash

set -eu

if ! [ "$(docker inspect -f '{{.State.Running}}' mediawiki-mediawiki-1)" = "true" ]; then
  echo "MediaWiki container is not running"
  exit 1
fi

docker cp "$(pwd)/isExtensionEnabled.php" mediawiki-mediawiki-1:/var/www/html/w/maintenance/isExtensionEnabled.php

REQUIRED_KEYS=('name' 'repository' 'configuration' 'bash')
MEDIAWIKI_PATH="../mediawiki"

yq() {
  echo "$2" | docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq eval "$1" -
}

validate_keys() {
  local manifest_content
  manifest_content=$1
  for key in "${REQUIRED_KEYS[@]}"; do
    value=$(yq ".${key}" "$manifest_content")
    if [ -z "$value" ] || [ "$value" = "null" ]; then
      echo "Missing key '$key' in manifest, skipping..."
      return 1
    fi
  done
  return 0
}

extension_is_enabled() {
  local extension_name
  extension_name=$1
  local output
  output=$(docker exec -it mediawiki-mediawiki-1 php maintenance/run.php isExtensionEnabled --extension="$extension_name")
  if [ "$output" == "1" ]; then
    return 0
  else
    return 1
  fi
}

install_extension() {
  local manifest
  manifest=$1
  if [ -z "$manifest" ] || [ ! -f "$manifest" ]; then
    echo "Manifest is not specified or file '$manifest' does not exist, skipping..."
    return
  fi
  manifest_content=$(cat "$manifest")
  if ! validate_keys "$manifest_content"; then
    echo "Invalid manifest '$manifest', skipping..."
    return
  fi
  name=$(yq '.name' "$manifest_content")
  if extension_is_enabled "$name"; then
    echo "Extension '$name' is already installed and active, skipping..."
    return
  fi
  repository=$(yq '.repository' "$manifest_content")
  if ! git clone "$repository" "$MEDIAWIKI_PATH/extensions/$name" --depth=1 2>&1; then
    echo "Failed to clone repository '$repository'"
    exit 1
  fi
  echo -e "\n# Configuration for '$name' extension" >>"$MEDIAWIKI_PATH/LocalSettings.php"
  configuration=$(yq '.configuration' "$manifest_content")
  echo -e "$configuration" >>"$MEDIAWIKI_PATH/LocalSettings.php"
  bash=$(yq '.bash' "$manifest_content")
  docker exec mediawiki-mediawiki-1 bash -c "$bash"
}

install_extensions() {
  for extension in "$@"; do
    local manifest
    manifest="./manifests/$extension.yaml"
    if [[ -f "$manifest" ]]; then
      install_extension "$manifest"
    else
      echo "No corresponding manifest file found for extension '$extension', skipping..."
    fi
  done
}

install_all_extensions() {
  for manifest in ./manifests/*.yaml; do
    install_extension "$manifest"
  done
}

"$@"
