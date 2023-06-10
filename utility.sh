#!/bin/bash

set -u

get_response_code() {
  echo "$(curl --write-out '%{http_code}' --silent --output /dev/null "$1")"
}

is_container_running() {
  is_running=$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)
  echo "${is_running:=false}"
}

are_containers_running() {
  local containers
  containers=("$@")

  for container in "${containers[@]}"; do
    is_running="$(is_container_running "$container")"

    if [ "$is_running" != "true" ]; then
      echo "false"
      return
    fi
  done
  echo "true"
}

is_container_present() {
  is_present=$(docker inspect "$1" >/dev/null 2>&1 && echo true || echo false)
  echo "$is_present"
}

are_containers_present() {
  local containers
  containers=("$@")

  for container in "${containers[@]}"; do
    is_present="$(is_container_present "$container")"

    if [ "$is_present" != "true" ]; then
      echo "false"
      return
    fi
  done

  echo "true"
}

is_container_env_var_set() {
  local container
  container=$1
  local var_name
  var_name=$2
  local expected_value
  expected_value=$3

  if docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$container" | grep -q "$var_name=$expected_value"; then
    echo "true"
  else
    echo "false"
  fi
}

open_url_when_available() {
  wait_until_url_available "$1"
  error_message="Unable to automatically open '$1', try opening it in a browser"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS system
    open ${2:+-a "$2"} "$1" || echo "$error_message"
  elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    # Linux system
    xdg-open "$1" || echo "$error_message"
  elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows system (Cygwin, Git Bash, or WSL)
    start "" "$1" || echo "$error_message"
  else
    echo "Unsupported operating system"
  fi
}

wait_until_url_available() {
  while ! [[ "$(get_response_code "$1")" =~ ^(200|301)$ ]]; do sleep 1; done
  sleep 0.5
}

apply_mediawiki_skin_settings() {
  local mediawiki_path
  mediawiki_path="$1"
  local wfLoadSkin
  wfLoadSkin="$2"
  local wgDefaultSkin
  wgDefaultSkin="$3"

  cd "$mediawiki_path" || exit
  grep -qx "^wfLoadSkin(['\"]${wfLoadSkin}['\"]); *$" LocalSettings.php || echo "wfLoadSkin(\"$wfLoadSkin\");" >>LocalSettings.php
  sed -i -E "s/\\\$wgDefaultSkin.*;[[:blank:]]*$/\\\$wgDefaultSkin = \"$wgDefaultSkin\";/g" LocalSettings.php
}

apply_mediawiki_skin() {
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

  cd "$mediawiki_path" || exit
  rm -rf "skins/$skin_folder_name"
  git clone --branch "$skin_branch" "$skin_repo_url" "./skins/$skin_folder_name" --depth=1
  sleep 1
  apply_mediawiki_skin_settings "$mediawiki_path" "$wfLoadSkin" "$wgDefaultSkin"
}

apply_mediawiki_extension_settings() {
  local mediawiki_path
  mediawiki_path="$1"
  local wfLoadExtension
  wfLoadExtension="$2"

  cd "$mediawiki_path" || exit
  grep -qx "^[[:blank:]]*wfLoadExtension[[:blank:]]*([[:blank:]]*[\"']${wfLoadExtension}[\"'][[:blank:]]*)[[:blank:]]*;[[:blank:]]*$" LocalSettings.php || echo "wfLoadExtension(\"$wfLoadExtension\");" >>LocalSettings.php
}

apply_mediawiki_extension() {
  local mediawiki_path
  mediawiki_path="$1"
  local extension_folder_name
  extension_folder_name="$2"
  local extension_repo_url
  extension_repo_url="$3"
  local extension_branch
  extension_branch="$4"
  local wfLoadExtension
  wfLoadExtension="$5"

  cd "$mediawiki_path" || exit
  rm -rf "extensions/$extension_folder_name"
  git clone --branch "$extension_branch" "$extension_repo_url" "./extensions/$extension_folder_name" --depth=1
  sleep 1
  apply_mediawiki_extension_settings "$mediawiki_path" "$wfLoadExtension"
}

confirm_action() {
  local prompt_message
  prompt_message="$1"
  read -p "${prompt_message} (y/n)? " -n 1 -r
  echo
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    return 1
  fi
  return 0
}

negate_boolean() {
  if [ "$1" = "true" ]; then
    echo "false"
  elif [ "$1" = "false" ]; then
    echo "true"
  else
    echo "Error: Invalid boolean value"
    exit 1
  fi
}

# Usage: print_duration_since_start start_time [format]
print_duration_since_start() {
  local start
  start=$1
  local format
  format=${2:-"Execution time: %d minutes, %d seconds."} # Use provided format, or default if not provided
  local end
  end=$(date +%s)
  local duration
  duration=$((end - start))
  local minutes
  minutes=$((duration / 60))
  local seconds
  seconds=$((duration % 60))
  # shellcheck disable=SC2059
  printf "$format\n" "$minutes" "$seconds"
}
