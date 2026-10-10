<?php

wfLoadExtension( 'Sanctions' );

// Sanctions creates its tables only on MySQL, and Quickstart defaults to SQLite
$wgHooks['LoadExtensionSchemaUpdates'][] = static function ( $updater ) {
	if ( $updater->getDB()->getType() === 'sqlite' ) {
		$updater->addExtensionTable( 'sanctions', __DIR__ . '/sanctions.sqlite.sql' );
	}
};
