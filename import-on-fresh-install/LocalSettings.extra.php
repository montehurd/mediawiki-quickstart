<?php

// This file gets included in the base LocalSettings.php file so you can easily add values
// Reminder, you can shell into the mediawiki container and check that values specified here
// have taken effect by using a command similar to this:
//    echo 'var_dump($wgMaxArticleSize);' | php maintenance/run.php eval.php

// Increase size to 200 MB
$wgMaxArticleSize = 20480;

// Your other overrides below:
