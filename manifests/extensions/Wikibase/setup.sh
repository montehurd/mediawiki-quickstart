#!/bin/bash

php maintenance/run.php ./extensions/Wikibase/lib/maintenance/populateSitesTable.php
php maintenance/run.php ./extensions/Wikibase/repo/maintenance/rebuildItemsPerSite.php
php maintenance/run.php ./maintenance/populateInterwiki.php