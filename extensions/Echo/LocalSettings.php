<?php

wfLoadExtension( 'Echo' );
# Default user notification preferences
$wgDefaultUserOptions['echo-subscriptions-email-edit-user-talk'] = true;
$wgDefaultUserOptions['echo-subscriptions-web-edit-user-talk'] = true;
$wgDefaultUserOptions['echo-subscriptions-email-mention'] = true;
$wgDefaultUserOptions['echo-subscriptions-web-mention'] = true;
