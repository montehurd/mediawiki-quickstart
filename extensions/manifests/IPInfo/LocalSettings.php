<?php

wfLoadExtension( 'IPInfo' );
$wgGroupPermissions['*']['ipinfo'] = true;
$wgGroupPermissions['*']['ipinfo-view-basic'] = true;
$wgGroupPermissions['*']['ipinfo-view-full'] = true;
$wgGroupPermissions['*']['ipinfo-view-log'] = true;