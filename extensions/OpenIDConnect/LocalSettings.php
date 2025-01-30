<?php

wfLoadExtension( 'OpenIDConnect' );
$wgPluggableAuth_Config = [
  "Keycloak" => [
    'plugin' => 'OpenIDConnect',
    'data' => [
      'providerURL' => 'http://' . $_SERVER['HOST_IP'] . ':8888/realms/test',
      'clientID' => 'wiki',
      'clientsecret' => $_SERVER['CLIENT_SECRET']
    ]
  ]
];
