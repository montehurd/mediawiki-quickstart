#!/bin/bash

set -eu

get_response_code() {
  # shellcheck disable=SC2005
  echo "$(curl --write-out '%{http_code}' --silent --output /dev/null "$1")"
}

is_container_running() {
  if [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]; then
    return 0
  else
    return 1
  fi
}

are_containers_running() {
  local containers
  containers=("$@")

  for container in "${containers[@]}"; do
    if ! is_container_running "$container"; then
      return 1
    fi
  done
  return 0
}

is_container_present() {
  docker inspect "$1" >/dev/null 2>&1
  return $?
}

are_containers_present() {
  local containers
  containers=("$@")

  for container in "${containers[@]}"; do
    if ! is_container_present "$container"; then
      return 1
    fi
  done
  return 0
}

is_container_env_var_set() {
  local container
  container=$1
  local var_name
  var_name=$2
  local expected_value
  expected_value=$3

  if docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$container" | grep -q "$var_name=$expected_value"; then
    return 0
  else
    return 1
  fi
}

is_network_connected_to_container() {
  local network_name
  network_name=$1
  local container_name
  container_name=$2
  docker network inspect "$network_name" --format '{{range .Containers}}{{.Name}} {{end}}' | grep -wq "$container_name"
}

connect_network_to_container() {
  local network_name=$1
  local container_name=$2
  if is_network_connected_to_container "$network_name" "$container_name"; then
    echo "Container $container_name is already connected to $network_name"
    return 0
  fi
  echo "Connecting $container_name to $network_name..."
  if docker network connect "$network_name" "$container_name"; then
    return 0
  fi
  echo "Failed to connect $container_name to $network_name"
  return 1
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

is_dir_empty() {
  if [ ! "$(ls "$1")" ]; then
    return 0
  else
    return 1
  fi
}
