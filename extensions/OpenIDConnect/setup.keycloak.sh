#!/bin/bash

REALM=test
CLIENT=wiki
USERNAME=testuser
PASSWORD=testpass

# login to keycloak
/opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD

# create realm
/opt/keycloak/bin/kcadm.sh create realms --set enabled=true --set realm=$REALM

# create client, saving client id
CID=$(/opt/keycloak/bin/kcadm.sh create clients --target-realm $REALM --set clientId=$CLIENT --set 'redirectUris=["http://*"]' --id)

# create client secret for client
/opt/keycloak/bin/kcadm.sh create clients/${CID}/client-secret --target-realm $REALM

# create user
/opt/keycloak/bin/kcadm.sh create users --target-realm $REALM --set username=$USERNAME --set enabled=true

# create password for user
/opt/keycloak/bin/kcadm.sh set-password --target-realm $REALM --username $USERNAME --new-password $PASSWORD

# echo client secret
CLIENT_SECRET=$(/opt/keycloak/bin/kcadm.sh get clients/${CID}/client-secret --target-realm $REALM --fields value --format csv --noquotes)
echo "CLIENT_SECRET=$CLIENT_SECRET" >> /root/.env
