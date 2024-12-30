<?php

wfLoadExtension( 'CheckUser' );
$wgGroupPermissions['checkuser']['checkuser'] = true;
$wgGroupPermissions['checkuser']['checkuser-log'] = true;
$wgGroupPermissions['checkuser']['investigate'] = true;
$wgGroupPermissions['checkuser']['checkuser-get-actions'] = true;
$wgGroupPermissions['checkuser']['checkuser-get-users'] = true;
$wgCheckUserEnableSpecialInvestigate = true;
$wgCheckUserMaximumRowCount = 3;
$wgCheckUserDeveloperMode = true;
$wgGroupPermissions['Check users'] = $wgGroupPermissions['checkuser'];
