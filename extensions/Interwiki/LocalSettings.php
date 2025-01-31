<?php

wfLoadExtension( 'Interwiki' );

// To grant a group (e.g., the "sysop" group) permission to edit interwiki data
$wgGroupPermissions['sysop']['interwiki'] = true;