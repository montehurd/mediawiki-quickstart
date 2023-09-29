#!/bin/bash

set -eu

_get_required_keys() {
  echo 'name' 'repository' 'configuration'
}

_EXTENSIONS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

_get_script_path() {
  echo "$_EXTENSIONS_PATH"
}

source "$(_get_script_path)/php.sh"
source "$(_get_script_path)/node.sh"
docker cp "$(_get_script_path)/isExtensionEnabled.php" mediawiki-mediawiki-1:/var/www/html/w/maintenance/isExtensionEnabled.php >/dev/null

_get_mediawiki_path() {
  echo "$(_get_script_path)/../mediawiki"
}

_ensure_containers_running() {
  if ! [ "$(docker inspect -f '{{.State.Running}}' mediawiki-mediawiki-1)" = "true" ]; then
    echo "MediaWiki container is not running"
    return 1
  fi
  return 0
}

_yq() {
  echo "$2" | docker run --rm -i -v "$(_get_script_path):/workdir" mikefarah/yq eval "$1" -
}

_validate_keys() {
  local value
  local manifest_content
  manifest_content=$1
  for key in $(_get_required_keys); do
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

# Note: caller must declare the following:
#   declare -a INSTALLED_EXTENSIONS=()
_install_from_manifest() {
  local manifest
  manifest=$1
  echo -e "\nInstalling $manifest"
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
      _install_from_manifest "$(_get_script_path)/manifests/$dependency.yml"
    done
  fi
  local repository
  repository=$(_yq '.repository' "$manifest_content")
  if ! git clone --recurse-submodules "$repository" "$(_get_mediawiki_path)/extensions/$name" --depth=1 >/dev/null 2>&1; then
    echo "Failed to clone repository '$repository'"
    exit 1
  fi
  echo -e "\n# Configuration for '$name' extension" >>"$(_get_mediawiki_path)/LocalSettings.php"
  local configuration
  configuration=$(_yq '.configuration' "$manifest_content")
  echo -e "$configuration" >>"$(_get_mediawiki_path)/LocalSettings.php"
  local bash
  bash=$(_yq '.bash' "$manifest_content")
  if [ -n "$bash" ] && [ "$bash" != "null" ]; then
    docker exec -u root mediawiki-mediawiki-1 bash -c "$bash"
  fi

  INSTALLED_EXTENSIONS+=("$name")
}

_install_php_and_node_dependencies() {
  if [[ ${#INSTALLED_EXTENSIONS[@]} -eq 0 ]]; then
    return
  fi
  if ! install_php_dependencies_for_extensions "${INSTALLED_EXTENSIONS[@]}"; then
    echo "Failed to install php dependencies"
    exit 1
  fi
  if ! install_node_dependencies_for_extensions "${INSTALLED_EXTENSIONS[@]}"; then
    echo "Failed to install node dependencies"
    exit 1
  fi
}