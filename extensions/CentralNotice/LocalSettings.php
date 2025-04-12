<?php

wfLoadExtension( 'CentralNotice' );

$wgNoticeInfrastructure = true;
$wgNoticeProject = 'centralnoticeproject'; # 'centralnoticeproject' can be any string
$wgNoticeProjects = [ $wgNoticeProject ];
$wgCentralHost = $wgServer;
$wgCentralSelectedBannerDispatcher = "$wgServer$wgScriptPath/index.php?title=Special:BannerLoader";
$wgCentralDBname = $wgDBname;
$wgCentralNoticeGeoIPBackgroundLookupModule = 'ext.centralNotice.freegeoipLookup';