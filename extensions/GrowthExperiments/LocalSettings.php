<?php

wfLoadExtension( 'GrowthExperiments' );

$wgGEDeveloperSetup = true;

// Content handler hooks needed for test fixture subpages (/addimage.json, /tone.json)
// to be imported with the correct content model by the PrepareBrowserTests maintenance script.
$wgHooks['ContentHandlerDefaultModelFor'][] =
	\GrowthExperiments\NewcomerTasks\AddImage\SubpageImageRecommendationProvider::class . '::onContentHandlerDefaultModelFor';
$wgHooks['ContentHandlerDefaultModelFor'][] =
	\GrowthExperiments\NewcomerTasks\ReviseTone\SubpageReviseToneRecommendationProvider::class . '::onContentHandlerDefaultModelFor';
$wgHooks['MediaWikiServices'][] =
	\GrowthExperiments\NewcomerTasks\AddImage\SubpageImageRecommendationProvider::class . '::onMediaWikiServices';
