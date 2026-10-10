<?php

wfLoadExtension( 'WikiLambda' );
$wgWikiLambdaEnableRepoMode = true;
$wgWikiLambdaEnableClientMode = true;
$wgWikiLambdaOrchestratorLocation = 'http://mediawiki-function-orchestrator-1:6254/1/v1/evaluate';
# Server-side function calls (abstract fragment renders, {{#function}}) target this wiki,
# whose API the PHP containers reach only through the mediawiki-web service
$wgWikiLambdaClientTargetAPI = 'http://mediawiki-web:8080';
