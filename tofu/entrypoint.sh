#!/bin/bash

# Set up TF_VAR versions of environment variables
export TF_VAR_os_auth_url=$OS_AUTH_URL
export TF_VAR_os_application_credential_id=$OS_APPLICATION_CREDENTIAL_ID
export TF_VAR_os_application_credential_secret=$OS_APPLICATION_CREDENTIAL_SECRET
export TF_VAR_os_project_id=${OS_PROJECT_ID:-mediawiki-quickstart}

verify_credentials() {
  [[ -n "$OS_APPLICATION_CREDENTIAL_ID" && -n "$OS_APPLICATION_CREDENTIAL_SECRET" ]] || \
    { echo -e "Error:\n\tSet 'OS_APPLICATION_CREDENTIAL_ID' and 'OS_APPLICATION_CREDENTIAL_SECRET' in 'tofu/.env' first\n\tThen run 'source .env' to make those values available to your calls to the 'import' script and subsequent tofu commands"; exit 1; }
}

verify_project() {
  local project="$1"
  [[ -z "$project" ]] && { echo "Error: project is required" >&2; exit 1; }
  local current_project=$(openstack token issue -f value -c project_id | xargs openstack project show -f value -c name 2>/dev/null)
  [[ "$current_project" == "$project" ]] || \
    { echo "Error: Wrong project. Expected '$project' but got '$current_project'"; exit 1; }
}

import() {
  verify_credentials
  verify_project "$PROJECT_NAME"
  tofu init
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  import "$@"
fi

exec /bin/bash