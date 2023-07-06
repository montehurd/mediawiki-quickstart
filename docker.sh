#!/bin/bash

set -eu

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
