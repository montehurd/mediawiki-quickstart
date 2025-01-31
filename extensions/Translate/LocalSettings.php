<?php

wfLoadExtension( 'Translate' );

$wgGroupPermissions['translator']['translate'] = true;
$wgGroupPermissions['translator']['skipcaptcha'] = true; // T36182: needed with ConfirmEdit
$wgTranslateDocumentationLanguageCode = 'qqq';

# Add this if you want to enable access to page translation
$wgGroupPermissions['sysop']['pagetranslation'] = true;

# Private api keys for machine translation services
#$wgTranslateTranslationServices['Apertium']['key'] = '';