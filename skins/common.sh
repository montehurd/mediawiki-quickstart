#!/bin/bash

set -eu

_get_required_keys() {
  echo 'name' 'repository' 'branch' 'wfLoadSkin' 'wgDefaultSkin'
}

_get_script_path() {
  echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
}

_get_mediawiki_path() {
  echo "$(_get_script_path)/../mediawiki"
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

_apply_mediawiki_skin_settings() {
  local mediawiki_path
  mediawiki_path="$1"
  local wfLoadSkin
  wfLoadSkin="$2"
  local wgDefaultSkin
  wgDefaultSkin="$3"

  (
    cd "$mediawiki_path" || exit 1
    grep -qx "^wfLoadSkin(['\"]${wfLoadSkin}['\"]); *$" LocalSettings.php || echo -e "\n# Configuration for '$wfLoadSkin' skin\nwfLoadSkin(\"$wfLoadSkin\");" >>LocalSettings.php || exit 1
    sed -i -E "s/\\\$wgDefaultSkin.*;[[:blank:]]*$/\\\$wgDefaultSkin = \"$wgDefaultSkin\";/g" LocalSettings.php || exit 1
  ) && return 0 || return 1
}

_apply_mediawiki_skin() {
  local mediawiki_path
  mediawiki_path="$1"
  local skin_folder_name
  skin_folder_name="$2"
  local skin_repo_url
  skin_repo_url="$3"
  local skin_branch
  skin_branch="$4"
  local wfLoadSkin
  wfLoadSkin="$5"
  local wgDefaultSkin
  wgDefaultSkin="$6"

  (
    cd "$mediawiki_path" || exit 1
    rm -rf "skins/$skin_folder_name"
    if ! git clone --quiet --branch "$skin_branch" "$skin_repo_url" "./skins/$skin_folder_name" --depth=1; then
      echo "Failed to clone the repository"
      exit 1
    fi
    sleep 1
    if ! _apply_mediawiki_skin_settings "$mediawiki_path" "$wfLoadSkin" "$wgDefaultSkin"; then
      echo "Failed to apply skin settings"
      exit 1
    fi
  ) && return 0 || return 1
}

_install_from_manifest() {
  local manifest
  manifest="$1"
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

  local repository
  repository=$(_yq '.repository' "$manifest_content")

  local branch
  branch=$(_yq '.branch' "$manifest_content")

  local wfLoadSkin
  wfLoadSkin=$(_yq '.wfLoadSkin' "$manifest_content")

  local wgDefaultSkin
  wgDefaultSkin=$(_yq '.wgDefaultSkin' "$manifest_content")

  echo "$repository"

  if _apply_mediawiki_skin "$(_get_mediawiki_path)" "$name" "$repository" "$branch" "$wfLoadSkin" "$wgDefaultSkin"; then
    echo "Successfully installed $name"
  else
    echo "Failed to install $name"
  fi
}

_ensure_containers_running() {
  if ! [ "$(docker inspect -f '{{.State.Running}}' mediawiki-mediawiki-1)" = "true" ]; then
    echo "MediaWiki container is not running"
    return 1
  fi
  return 0
}