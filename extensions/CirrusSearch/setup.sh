#!/bin/bash

php maintenance/run.php ./extensions/CirrusSearch/maintenance/UpdateSearchIndexConfig.php
php maintenance/run.php ./extensions/CirrusSearch/maintenance/ForceSearchIndex.php --skipLinks --indexOnSkip
php maintenance/run.php ./extensions/CirrusSearch/maintenance/ForceSearchIndex.php --skipParse
php maintenance/run.php ./maintenance/runJobs.php
php maintenance/run.php ./extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php