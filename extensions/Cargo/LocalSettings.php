<?php

wfLoadExtension( 'Cargo' );

// Cargo's own connection needs its own SQLite file: on the wiki's file it waits
// out the write lock a POST request's main connection holds (T371791).
if ( $wgDBtype === 'sqlite' ) {
	$wgCargoDBfilePath = "$wgSQLiteDataDir/{$wgDBname}_cargo.sqlite";
}
