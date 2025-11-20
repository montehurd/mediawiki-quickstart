#!/bin/bash

REALM=test
CLIENT=wiki
USERNAME=testuser
PASSWORD=testpass

check_keycloak() {
  exec 3<>/dev/tcp/localhost/8080
  if [ $? -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# attempt to login to keycloak
MAX_RETRIES=24
RETRY_COUNT=0
while true; do
  if check_keycloak; then
    /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD
    if [ $? -eq 0 ]; then
      break
    fi
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "Authentication failed after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "Authentication failed, retrying..."
  sleep 5
done

# create realm
/opt/keycloak/bin/kcadm.sh create realms --set enabled=true --set realm=$REALM

# create user
TEST_USER_UUID=$(/opt/keycloak/bin/kcadm.sh create users --target-realm $REALM --set username=$USERNAME --set email=test@example.com --set firstName=Test --set lastName=User --set enabled=true --id)
echo "TEST_USER_UUID=$TEST_USER_UUID" >>/root/.env

# create password for user
/opt/keycloak/bin/kcadm.sh set-password --target-realm $REALM --username $USERNAME --new-password $PASSWORD

# create client, saving client id
CLIENT_UUID=$(/opt/keycloak/bin/kcadm.sh create clients --target-realm $REALM --set clientId=$CLIENT --id)
echo "CLIENT_UUID=$CLIENT_UUID" >>/root/.env

/opt/keycloak/bin/kcadm.sh update clients/$CLIENT_UUID --target-realm $REALM --set 'redirectUris=["http://*"]'
/opt/keycloak/bin/kcadm.sh update clients/$CLIENT_UUID --target-realm $REALM --body "{\"attributes\": {\"backchannel.logout.url\": \"http://host:8080/w/rest.php/pluggableauth/v1/logout\", \"backchannel.logout.session.required\": \"false\"}}"

# create client secret for client
/opt/keycloak/bin/kcadm.sh create clients/${CLIENT_UUID}/client-secret --target-realm $REALM

# echo client secret
CLIENT_SECRET=$(/opt/keycloak/bin/kcadm.sh get clients/${CLIENT_UUID}/client-secret --target-realm $REALM --fields value --format csv --noquotes)
echo "CLIENT_SECRET=$CLIENT_SECRET" >>/root/.env
