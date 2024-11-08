#!/bin/bash

set -eu

source "./config"
source "./installer/php.sh"
source "./installer/node.sh"
source "./common/utility.sh"

docker cp "$SCRIPT_PATH/isComponentEnabled.php" mediawiki-mediawiki-1:/var/www/html/w/maintenance/isComponentEnabled.php >/dev/null

_get_component_type() {
  local component_path="$1"
  dirname "$component_path"
}

_get_component_name() {
  local component_path="$1"
  basename "$component_path"
}

_get_manifest_path() {
  local component_path="$1"
  echo "manifests/$component_path"
}

_ensure_containers_running() {
  if ! [ "$(docker inspect -f '{{.State.Running}}' mediawiki-mediawiki-1)" = "true" ]; then
    echo "MediaWiki container is not running"
    return 1
  fi
  return 0
}

_yq() {
  echo "$2" | docker run --rm -i -v "$SCRIPT_PATH:/workdir" mikefarah/yq eval "$1" -
}

_is_component_enabled() {
  local component_path="$1"
  local output
  output=$(docker exec mediawiki-mediawiki-1 php maintenance/run.php isComponentEnabled --component="$(_get_component_name "$component_path")" --type="$(_get_component_type "$component_path")")
  if [ "$output" == "1" ]; then
    return 0
  else
    return 1
  fi
}

_get_dependencies() {
  local component_path="$1"
  local dependencies_file="./$(_get_manifest_path "$component_path")/dependencies.yml"
  if [ -f "$dependencies_file" ]; then
    _yq '.[]' "$(cat "$dependencies_file")"
  else
    echo ""
  fi
}

_get_component_local_settings_path() {
  local component_path="$1"
  echo "./$(_get_manifest_path "$component_path")/LocalSettings.php"
}

# Note: caller must declare the following:
#   declare -a INSTALLED_COMPONENTS=()
_install_from_manifest() {
  local component_path="$1"
  local local_settings_path="$(_get_component_local_settings_path "$component_path")"
 
  echo -e "\nInstalling '$(_get_component_name "$component_path")'"

  if [ ! -f "$local_settings_path" ]; then
    printf "    \e[31mRequired '%s' does not exist\e[0m\n\
    There is a folder for skins and a folder for extensions\n\
    Ensure your component's manifest folder is in the correct one,\n\
    containing its own 'LocalSettings.php'\n\
\e[31mExiting\e[0m\n" "$local_settings_path"
    exit 1
  fi
 
  if _is_component_enabled "$component_path"; then
    echo "Component '$(_get_component_name "$component_path")' is already installed and active, skipping..."
    return
  fi
 
  local dependencies
  dependencies=$(_get_dependencies "$component_path")
  if [ -n "$dependencies" ]; then
    for dependency in $dependencies; do
      echo "Installing '$(_get_component_name "$component_path")' dependency '$dependency'"
      _install_from_manifest "$dependency"
    done
  fi

  local clone_depth="--depth=${CLONE_DEPTH:-2}"
  # `git clone --depth=0` fails with `fatal: depth 0 is not a positive number`.
  # For `CLONE_DEPTH=0`, skip `--depth` argument.
  # See T376791.
  if [ "${CLONE_DEPTH:-1}" -eq 0 ]; then
    local clone_depth=""
  fi

  # Generate the repository URL based on component type and name
  local repository
  repository="$GIT_CLONE_BASE_URL/$component_path"
  
  if ! git clone --recurse-submodules --progress "$repository" "$MEDIAWIKI_PATH/$component_path" $clone_depth 2>&1 | verboseOrDotPerLine "Git clone '$repository' $clone_depth to '$component_path'" "use CLONE_DEPTH=0 for full depth"; then
    echo "Failed to clone repository '$repository'"
    exit 1
  fi
 
  # Include the component's LocalSettings.php in MediaWiki's LocalSettings.php
  echo -e "\n# Local settings for '$(_get_component_name "$component_path")' $(_get_component_type "$component_path")" >>"$MEDIAWIKI_PATH/LocalSettings.php"
  echo "require_once \"\$IP/$(_get_manifest_path "$component_path")/LocalSettings.php\";" >>"$MEDIAWIKI_PATH/LocalSettings.php"

  INSTALLED_COMPONENTS+=("$component_path")
}

_import_page_dumps_for_installed_components() {
    if [[ ${#INSTALLED_COMPONENTS[@]} -eq 0 ]]; then
        return
    fi
    local folders=()
    for component_path in "${INSTALLED_COMPONENTS[@]}"; do
        local pages_folder="$(_get_manifest_path "$component_path")/pages"
        if [ -d "$pages_folder" ]; then
            folders+=("$pages_folder")
        fi
    done
    if [ ${#folders[@]} -gt 0 ]; then
        echo "Importing pages from installed components"
        docker exec -u "$HOST_UID:$HOST_GID" -i mediawiki-mediawiki-1 bash /import_page_xml.sh "${folders[@]}"
    else
        echo "No pages to import found in any installed components, skipping..."
    fi
}

_run_bash_for_installed_components() {
  if [[ ${#INSTALLED_COMPONENTS[@]} -eq 0 ]]; then
    return
  fi
  for component_path in "${INSTALLED_COMPONENTS[@]}"; do
    _run_bash_from_manifest "$component_path"
  done
}

_run_bash_from_manifest() {
  local component_path="$1"
  local setup_script="./$(_get_manifest_path "$component_path")/setup.sh"
  docker exec -u root mediawiki-mediawiki-1 bash -c "
    echo \"Looking for '${setup_script}'\"
    if [ -f \"${setup_script}\" ]; then
      echo \"Running setup script '${setup_script}'\"
      chmod +x \"${setup_script}\"
      \"${setup_script}\"
    else
      echo \"No '${setup_script}' found, skipping...\"
    fi
  " 2>&1 | verboseOrDotPerLine "Running '$setup_script', if present..."
}

_install_php_and_node_dependencies() {
  if [[ ${#INSTALLED_COMPONENTS[@]} -eq 0 ]]; then
    return
  fi
  if ! install_php_dependencies_for_components "$MEDIAWIKI_PATH" "${INSTALLED_COMPONENTS[@]}"; then
    echo "Failed to install php dependencies"
    exit 1
  fi
  if ! install_node_dependencies_for_components "$MEDIAWIKI_PATH" "${INSTALLED_COMPONENTS[@]}"; then
    echo "Failed to install node dependencies"
    exit 1
  fi
}

_rebuild_localization_cache() {
  sleep 1
  if [[ ${#INSTALLED_COMPONENTS[@]} -eq 0 ]]; then
    return
  fi
  docker exec -u root mediawiki-mediawiki-1 bash -c "php maintenance/rebuildLocalisationCache.php --force" 2>&1 | verboseOrDotPerLine "Rebuild mediawiki localization cache"
}