<?php

wfLoadExtension( 'SecurityApi' );
// eg. http://host.docker.internal:6927
// $wgSecurityApiUrl = 'http://host.docker.internal:6927';
$wgGroupPermissions['sysop']['securityapi-feed'] = true;
