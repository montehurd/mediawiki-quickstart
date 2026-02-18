#!/bin/bash

cd /var/www/html/w

# Import test fixture data (wiki pages and link recommendations) needed by Cypress tests.
php maintenance/run.php GrowthExperiments:PrepareBrowserTests

# GrowthExperiments' cypress.config.ts runs the above maintenance script via before:run,
# but the selenium container where tests run doesn't have PHP. Setting MW_MAINTENANCE_COMMAND
# to /bin/true makes the before:run handler no-op since we already ran it here during install.
grep -q '^export MW_MAINTENANCE_COMMAND=' .env 2>/dev/null || echo 'export MW_MAINTENANCE_COMMAND=/bin/true' >> .env
