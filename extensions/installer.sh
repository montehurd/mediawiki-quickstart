#!/bin/bash

set -eu

if ! [ "$(docker inspect -f '{{.State.Running}}' mediawiki-mediawiki-1)" = "true" ]; then
  echo "MediaWiki container is not running"
  exit 1
fi

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

docker cp "$SCRIPT_PATH/isExtensionEnabled.php" mediawiki-mediawiki-1:/var/www/html/w/maintenance/isExtensionEnabled.php >/dev/null

REQUIRED_KEYS=('name' 'repository' 'configuration')
MEDIAWIKI_PATH="$SCRIPT_PATH/../mediawiki"

source "$SCRIPT_PATH/php.sh"
source "$SCRIPT_PATH/node.sh"

_yq() {
  echo "$2" | docker run --rm -i -v "$SCRIPT_PATH:/workdir" mikefarah/yq eval "$1" -
}

_validate_keys() {
  local value
  local manifest_content
  manifest_content=$1
  for key in "${REQUIRED_KEYS[@]}"; do
    value=$(_yq ".${key}" "$manifest_content")
    if [ -z "$value" ] || [ "$value" = "null" ]; then
      echo "Missing key '$key' in manifest, skipping..."
      return 1
    fi
  done
  return 0
}

_is_extension_enabled() {
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

_install_from_manifest() {
  local manifest
  manifest=$1
  if [ -z "$manifest" ] || [ ! -f "$manifest" ]; then
    echo "Manifest is not specified or file '$manifest' does not exist, skipping..."
    return
  fi
  local manifest_content
  manifest_content=$(cat "$manifest")
  if ! _validate_keys "$manifest_content"; then
    echo "Invalid manifest '$manifest', skipping..."
    return
  fi
  local name
  name=$(_yq '.name' "$manifest_content")
  if _is_extension_enabled "$name"; then
    echo "Extension '$name' is already installed and active, skipping..."
    return
  fi
  local dependencies
  dependencies=$(_yq '.dependencies[]' "$manifest_content")
  if [ -n "$dependencies" ]; then
    for dependency in $dependencies; do
      echo "Installing '$name' dependency '$dependency'"
      _install_from_manifest "$SCRIPT_PATH/manifests/$dependency.yml"
    done
  fi
  local repository
  repository=$(_yq '.repository' "$manifest_content")
  if ! git clone --recurse-submodules "$repository" "$MEDIAWIKI_PATH/extensions/$name" --depth=1 >/dev/null 2>&1; then
    echo "Failed to clone repository '$repository'"
    exit 1
  fi
  echo -e "\n# Configuration for '$name' extension" >>"$MEDIAWIKI_PATH/LocalSettings.php"
  local configuration
  configuration=$(_yq '.configuration' "$manifest_content")
  echo -e "$configuration" >>"$MEDIAWIKI_PATH/LocalSettings.php"
  local bash
  bash=$(_yq '.bash' "$manifest_content")
  if [ -n "$bash" ] && [ "$bash" != "null" ]; then
    docker exec -u root mediawiki-mediawiki-1 bash -c "$bash"
  fi

  INSTALLED_EXTENSIONS+=("$name")
}

declare -a INSTALLED_EXTENSIONS=()

_install_php_and_node_dependencies() {
  if [[ ${#INSTALLED_EXTENSIONS[@]} -eq 0 ]]; then
    return
  fi
  install_php_dependencies_for_extensions "${INSTALLED_EXTENSIONS[@]}"
  install_node_dependencies_for_extensions "${INSTALLED_EXTENSIONS[@]}"
}

install() {
  INSTALLED_EXTENSIONS=()
  for extension in "$@"; do
    local manifest
    manifest="$SCRIPT_PATH/manifests/$extension.yml"
    if [[ -f "$manifest" ]]; then
      _install_from_manifest "$manifest"
    else
      echo "No corresponding manifest file found for extension '$extension', skipping..."
    fi
  done
  _install_php_and_node_dependencies
}

install_all() {
  INSTALLED_EXTENSIONS=()
  for manifest in "${SCRIPT_PATH}/manifests/"*.yml; do
    _install_from_manifest "$manifest"
  done
  _install_php_and_node_dependencies
}

"$@"
