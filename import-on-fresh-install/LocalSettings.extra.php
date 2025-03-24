<?php

// Quickstart modifies Mediawiki's LocalSettings.php to include this file
// Then, in this included file, we add everything Quickstart needs
// ( keeps changes to Mediawiki's LocalSettings.php to a minimum )
//
// Reminder, you can shell into the mediawiki container
// and check that values specified here have taken effect
// by using a command similar to this:
//    echo 'var_dump($wgMaxArticleSize);' | php maintenance/run.php eval.php

// Increase size to 200 MB
$wgMaxArticleSize = 20480;

// $wgShowExceptionDetails = true;

# Include default skin configuration
require_once "$IP/Skin.default.php";

# Include component configurations
require_once "$IP/Components.php";

# Include any other LocalSettings.*.php files - such
# files provide an easy way for users to override core
# or Component.php settings
#
# Simply create a "import-on-fresh-install/LocalSettings.#YOUR_STUFF#.php"
# file and it will get automatically added/linked
foreach (glob(__DIR__ . "/LocalSettings.*.php") as $filename) {
    if (strtolower(basename($filename)) !== 'localsettings.extra.php') {
        require_once $filename;
    }
}