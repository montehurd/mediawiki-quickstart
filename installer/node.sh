#!/bin/bash

set -eu

_components_with_file() {
    local file_name="$1"
    shift
    local components=("$@")
    local valid_components=()
    for component in "${components[@]}"; do
        if [[ -f "$MEDIAWIKI_PATH/$component/$file_name" ]]; then
            valid_components+=("$component")
        fi
    done
    echo "${valid_components[@]}"
}

_recursively_chown_node_modules_files_to_host_user() {
  docker exec -u root mediawiki-mediawiki-web-1 sh -c "find . -type d -name 'node_modules' -exec chown -R $(id -u):$(id -g) {} +"
}

install_node_dependencies_for_components() {
    local components=("$@")

    local components_with_package_lock_json=($(_components_with_file "package-lock.json" "${components[@]}"))
    local components_with_package_json=($(_components_with_file "package.json" "${components[@]}"))
    
    if [[ ${#components_with_package_lock_json[@]} -eq 0 ]] && [[ ${#components_with_package_json[@]} -eq 0 ]]; then
        echo "No components with package-lock.json or package.json found. Exiting."
        return 0
    fi
    
    SECONDS=0

    if [[ ${#components_with_package_lock_json[@]} -gt 0 ]]; then
        echo -e "Installing Node dependencies for components with package-lock.json: ${components_with_package_lock_json[@]}"
        for component in "${components_with_package_lock_json[@]}"; do
          docker exec -u root mediawiki-mediawiki-web-1 bash -c "cd '$component' && npm ci 2>&1" \
            | verboseOrDotPerLine "Installing Node dependencies for '$component' using npm ci"
        done
    fi
    
    # Remove components with package-lock.json from components_with_package_json
    # ie only do a "npm install" if we haven't already done a "npm ci"
    for comp in "${components_with_package_lock_json[@]}"; do
        components_with_package_json=(${components_with_package_json[@]/$comp})
    done

    if [[ ${#components_with_package_json[@]} -gt 0 ]]; then
        echo -e "Installing Node dependencies for components with only package.json: ${components_with_package_json[@]}"
        for component in "${components_with_package_json[@]}"; do
          docker exec -u root mediawiki-mediawiki-web-1 bash -c "cd '$component' && npm install 2>&1" \
            | verboseOrDotPerLine "Installing Node dependencies for '$component' using npm install"
        done
    fi

    _recursively_chown_node_modules_files_to_host_user

    ELAPSED=$SECONDS
    echo "Duration for node dependency installation: $((ELAPSED/60)) minutes $((ELAPSED%60)) seconds"
}