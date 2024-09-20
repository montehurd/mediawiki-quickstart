#!/bin/bash

set -eu

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

_get_manifest_path() {
  local extension_name="$1"
  echo "$(_get_script_path)/manifests/$extension_name"
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

_get_dependencies() {
  local extension_name="$1"
  local dependencies_file="$(_get_manifest_path "$extension_name")/dependencies.yml"
  if [ -f "$dependencies_file" ]; then
    _yq '.[]' "$(cat "$dependencies_file")"
  else
    echo ""
  fi
}

_get_extension_local_settings_path() {
  local extension_name="$1"
  echo "$(_get_manifest_path "$extension_name")/LocalSettings.php"
}

# Note: caller must declare the following:
#   declare -a INSTALLED_EXTENSIONS=()
_install_from_manifest() {
  local extension_name="$1"
  local local_settings_path="$(_get_extension_local_settings_path "$extension_name")"
 
  echo -e "\nInstalling $extension_name"
 
  if [ ! -f "$local_settings_path" ]; then
    echo "Required '$local_settings_path' does not exist, skipping..."
    return
  fi
 
  if _is_extension_enabled "$extension_name"; then
    echo "Extension '$extension_name' is already installed and active, skipping..."
    return
  fi
 
  local dependencies
  dependencies=$(_get_dependencies "$extension_name")
  if [ -n "$dependencies" ]; then
    for dependency in $dependencies; do
      echo "Installing '$extension_name' dependency '$dependency'"
      _install_from_manifest "$dependency"
    done
  fi
  
  # Generate the repository URL from the extension name
  local repository="https://gerrit.wikimedia.org/r/mediawiki/extensions/$extension_name"
  
  if ! git clone --recurse-submodules "$repository" "$(_get_mediawiki_path)/extensions/$extension_name" --depth=1 >/dev/null 2>&1; then
    echo "Failed to clone repository '$repository'"
    exit 1
  fi
 
  # Include the extension's LocalSettings.php in MediaWiki's LocalSettings.php
  echo -e "\n# Local settings for '$extension_name' extension" >>"$(_get_mediawiki_path)/LocalSettings.php"
  echo "require_once \"\$IP/extensions/manifests/$extension_name/LocalSettings.php\";" >>"$(_get_mediawiki_path)/LocalSettings.php"

  INSTALLED_EXTENSIONS+=("$extension_name")
}

# bash execution needs to happen AFTER php and node dependencies have been installed 
# since sometimes the bash executed needs to do something with those libraries
_run_bash_for_installed_extensions() {
  if [[ ${#INSTALLED_EXTENSIONS[@]} -eq 0 ]]; then
    return
  fi
  for extension in "${INSTALLED_EXTENSIONS[@]}"; do
    _run_bash_from_manifest "$extension"
  done
}

_run_bash_from_manifest() {
  local extension_name="$1"
  output=$(docker exec -u root mediawiki-mediawiki-1 bash -c "
    setup_script=\"./extensions/manifests/${extension_name}/setup.sh\"
    if [ -f \"\$setup_script\" ]; then
      echo \"Running setup script for '${extension_name}'\"
      chmod +x \"\$setup_script\"
      \"\$setup_script\"
    else
      echo \"No '${extension_name}/setup.sh' found, skipping...\"
    fi
  ")
  echo "$output"
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

_rebuild_localization_cache() {
  sleep 1
  if [[ ${#INSTALLED_EXTENSIONS[@]} -eq 0 ]]; then
    return
  fi
  echo -e "\nRebuilding localization cache"
  docker exec -u root mediawiki-mediawiki-1 bash -c "php maintenance/rebuildLocalisationCache.php --force --no-progress"
}