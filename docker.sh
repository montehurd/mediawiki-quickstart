#!/bin/bash

set -eu

is_service_running() {
  if [ -n "$(docker compose ps -q "$1" 2>/dev/null)" ]; then
    return 0
  else
    return 1
  fi
}

are_services_running() {
  local services
  services=("$@")
  for service in "${services[@]}"; do
    if ! is_service_running "$service"; then
      return 1
    fi
  done
  return 0
}

is_container_present() {
  docker inspect "$1" >/dev/null 2>&1
  return $?
}

get_compose_version() {
  docker compose version --short 2>/dev/null
}

verify_compose_version() {
  echo -e "\nVerifying 'docker compose' version..."
  local required_major_version="${1:-}"
  local required_minor_version="${2:-}"
  local required_patch_version="${3:-}"
  if [ -z "$required_major_version" ]; then
    echo -e "Error: Required major version is not provided!\n"
    return 1
  fi
  if [ -z "$required_minor_version" ]; then
    echo -e "Error: Required minor version is not provided!\n"
    return 1
  fi
  if [ -z "$required_patch_version" ]; then
    echo -e "Error: Required patch version is not provided!\n"
    return 1
  fi

  local error_message="Failure! 'docker compose version' must be '${required_major_version}.${required_minor_version}.${required_patch_version}' or greater\nTo update see: https://docs.docker.com/compose/migrate/\n"

  local compose_version=$(get_compose_version)
  if [ -z "$compose_version" ]; then
    echo -e "$error_message"
    return 1
  fi

  local major_version=$(echo "$compose_version" | cut -d '.' -f 1 | tr -cd '0-9')
  local minor_version=$(echo "$compose_version" | cut -d '.' -f 2 | tr -cd '0-9')
  local patch_version=$(echo "$compose_version" | cut -d '.' -f 3 | tr -cd '0-9')

  if [ "$major_version" -gt "$required_major_version" ] \
    || { [ "$major_version" -eq "$required_major_version" ] && [ "$minor_version" -gt "$required_minor_version" ]; } \
    || { [ "$major_version" -eq "$required_major_version" ] && [ "$minor_version" -eq "$required_minor_version" ] && [ "$patch_version" -ge "$required_patch_version" ]; }; then
    echo -e "Success! 'docker compose version' is at least '${required_major_version}.${required_minor_version}.${required_patch_version}'\n"
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