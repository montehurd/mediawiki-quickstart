<?php

wfLoadExtension( 'NearbyPages' );

// No $wgNearbyPagesUrl override: the extension's default queries the
// en.wikipedia.org API, which works standalone. Pointing it at the local
// wiki requires GeoData (elastic-backed here, via CirrusSearch) plus
// geotagged content, without which Special:Nearby only renders an error.
