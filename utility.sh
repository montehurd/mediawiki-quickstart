#!/bin/bash

get_response_code() {
  echo $(curl --write-out '%{http_code}' --silent --output /dev/null "$1")
}

is_container_running() {
  is_running=$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)
  echo "${is_running:=false}"
}

are_containers_running() {
  local containers=$@
  for container in $containers
  do
    is_running=$(is_container_running $container)
    
    if [ "$is_running" != "true" ]; then
      echo "false"
      return
    fi
  done
  echo "true"
}

is_container_present() {
  is_present=$(docker inspect "$1" > /dev/null 2>&1 && echo true || echo false)
  echo "$is_present"
}

are_containers_present() {
  local containers=$@

  for container in $containers
  do
    is_present=$(is_container_present $container)

    if [ "$is_present" != "true" ]; then
      echo "false"
      return
    fi
  done

  echo "true"
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
  while ! [[ "$(get_response_code $1)" =~ ^(200|301)$ ]]; do sleep 1; done
  sleep 0.5
}

apply_mediawiki_skin_settings() {
  local mediawikiPath="$1"
  local wfLoadSkin="$2"
  local wgDefaultSkin="$3"

  cd "$mediawikiPath"
  grep -qx "^wfLoadSkin([\"']$wfLoadSkin[\"']); *$" LocalSettings.php || echo "wfLoadSkin(\"$wfLoadSkin\");" >>LocalSettings.php
  sed -i -E "s/\\\$wgDefaultSkin.*;[[:blank:]]*$/\\\$wgDefaultSkin = \"$wgDefaultSkin\";/g" LocalSettings.php
}

apply_mediawiki_skin() {
  local mediawikiPath="$1"
  local skinSubdirectory="$2"
  local skinRepoURL="$3"
  local skinBranch="$4"
  local wfLoadSkin="$5"
  local wgDefaultSkin="$6"

  cd "$mediawikiPath"
  rm -rf "skins/$skinSubdirectory"
  git clone --branch "$skinBranch" "$skinRepoURL" "./skins/$skinSubdirectory" --depth=1
  sleep 1
  apply_mediawiki_skin_settings "$mediawikiPath" "$wfLoadSkin" "$wgDefaultSkin"
}

apply_mediawiki_extension_settings() {
  cd "$mediawikiPath"
  grep -qx "^[[:blank:]]*wfLoadExtension[[:blank:]]*([[:blank:]]*[\"']$wfLoadExtension[\"'][[:blank:]]*)[[:blank:]]*;[[:blank:]]*$" LocalSettings.php || echo "wfLoadExtension(\"$wfLoadExtension\");" >>LocalSettings.php
}

apply_mediawiki_extension() {
  cd "$mediawikiPath"
  rm -rf "extensions/$extensionSubdirectory"
  git clone --branch "$extensionBranch" "$extensionRepoURL" "./extensions/$extensionSubdirectory" --depth=1
  sleep 1
  apply_mediawiki_extension_settings
}

confirm_action() {
  local prompt_message="$1"
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
