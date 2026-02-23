<?php

wfLoadExtension( 'PageTriage' );

$wgJobRunRate = 100;

// ORES & PageTriage configuration
$wgPageTriageDraftNamespaceId = 118;
$wgExtraNamespaces[ $wgPageTriageDraftNamespaceId ] = 'Draft';
$wgExtraNamespaces[ $wgPageTriageDraftNamespaceId + 1 ] = 'Draft_talk';
$wgPageTriageNoIndexUnreviewedNewArticles = true;
$wgPageTriageEnableCopyvio = true;
$wgPageTriageEnableOresFilters = true;
$wgOresWikiId = 'enwiki';
$wgOresModels = [
	'articlequality' => [ 'enabled' => true, 'namespaces' => [ 0 ], 'cleanParent' => true ],
	'draftquality' => [ 'enabled' => true, 'namespaces' => [ 0 ], 'types' => [ 1 ] ]
];