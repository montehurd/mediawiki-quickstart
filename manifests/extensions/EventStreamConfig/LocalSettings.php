<?php

wfLoadExtension( 'EventStreamConfig' );
// When $wgEventLoggingStreamNames is false (not falsy), the EventLogging
// JavaScript client will treat all streams as if they are configured and
// registered.
$wgEventLoggingStreamNames = false;
