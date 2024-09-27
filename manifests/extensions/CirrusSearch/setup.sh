#!/bin/bash

php extensions/CirrusSearch/maintenance/UpdateSearchIndexConfig.php
php extensions/CirrusSearch/maintenance/ForceSearchIndex.php --skipLinks --indexOnSkip
php extensions/CirrusSearch/maintenance/ForceSearchIndex.php --skipParse
php maintenance/runJobs.php
php extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php
