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

get_compose_version() {
  docker compose version --short 2>/dev/null
}

verify_compose_version() {
  echo -e "\nVerifying 'docker compose' version..."

  local required_major_version
  local error_message
  local compose_version
  local major_version

  required_major_version="${1:-}"
  if [ -z "$required_major_version" ]; then
    echo -e "Error: Required major version is not provided!\n"
    return 1
  fi

  error_message="Failure! 'docker compose version' must be $required_major_version or greater\nTo update see: https://docs.docker.com/compose/migrate/\n"

  compose_version=$(get_compose_version)
  if [ -z "$compose_version" ]; then
    echo -e "$error_message"
    return 1
  fi

  major_version=$(echo "$compose_version" | cut -d '.' -f 1)
  if [ -n "$major_version" ] && [ "$major_version" -ge "$required_major_version" ]; then
    echo -e "Success! 'docker compose version' is at least $required_major_version\n"
    return 0
  fi
  echo -e "$error_message"
  return 1
}

is_user_in_docker_group() {
  groups $USER | grep -q '\bdocker\b'
}

verify_docker_group() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Skipping Linux user group check"
    return 0
  fi
  if is_user_in_docker_group; then
    echo "User '$USER' is in the 'docker' group"
    return 0
  else
    echo "Error: User '$USER' is not in the 'docker' group"
    echo "Please run the following command to add '$USER' to the 'docker' group:"
    printf "\e[33msudo usermod -aG docker $USER\e[0m\n"
    echo -e "Afterwards, log out and log back in or reboot for the changes to take effect\n"
    return 1
  fi
}
