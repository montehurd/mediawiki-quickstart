Quickly spin up a MediaWiki instance with Docker

Easy skin and extension management via "component" manifest folders

Test running including Selenium tests you can watch as they execute

<details>
<summary><h2>Table of Contents</h2></summary>

[[_TOC_]]

</details>

# Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop) installed

# Installation

1. Clone the repository

```bash
git clone https://gitlab.wikimedia.org/repos/test-platform/mediawiki-quickstart.git
```

2. Navigate to the repository directory

```bash
cd ~/mediawiki-quickstart
```

# Usage

## Fetch, configure and start MediaWiki

- Fetches the latest MediaWiki (into `~/mediawiki-quickstart/mediawiki/`) and spins up its Docker containers

```bash
./fresh_install
```

# Troubleshooting

If `./fresh_install` doesn't work, you can try:

```bash
./remove
docker system prune -af
./fresh_install
```

Also, ensure you are running the latest Docker (or Docker Desktop) version - some older versions had bugs which prevented Mediawiki containers from running on some architectures

# Component management (installing skins/extensions)

Quickstart considers skins and extensions to be "components"

## Component manifests

A folder-based manifest format is used to define how extensions and skins are installed

You can see examples in the `~/mediawiki-quickstart/extensions/` and `~/mediawiki-quickstart/skins` directories

In these you will see one directory per extension/skin:

```text
extensions/
  |--IPInfo/
  |--Math/
  |--VisualEditor/
  ...
skins/
  |--MonoBook/
  |--Vector/
  |--Timeless/
  ...
```

## Component manifest folder contents

```text
extensions/
  |--IPInfo/
  |----LocalSettings.php       (required)
  |----setup.sh                (optional)
  |----dependencies.yml        (optional)
  |----pages/                  (optional)
  |----docker-compose.yml      (optional)
  |----setup.SERVICE_NAME.sh (optional)
  ...
skins/
  |--MonoBook/
  |----LocalSettings.php       (required)
  |----setup.sh                (optional)
  |----dependencies.yml        (optional)
  |----pages/                  (optional)
  |----docker-compose.yml      (optional)
  |----setup.SERVICE_NAME.sh (optional)
  ...
```

### LocalSettings.php (required)

In this file you put whatever settings your component needs to load/configure it

For many components, a single line of code is all that's needed:

```php
<?php

wfLoadExtension( 'FileImporter' );
```

or

```php
<?php

wfLoadSkin( 'Vector' );
```

QuickStart's component installer links your component's `LocalSettings.php` to Mediawiki's `LocalSettings.php` by adding an include to the latter. This allows you to more cleanly manage and reason about your component's settings

The installer automatically clones your components repo so you don't have to

### setup.sh (optional)

`setup.sh` is executed by the installer after your component's repo is cloned

This is where you can put any shell scripting that needs to execute to set up your component

It is executed relative to mediawiki's directory in the mediawiki container - i.e. `pwd` placed in your `setup.sh` will output `/var/www/html/w`

### dependencies.yml (optional)

This is where you can define other components that must be installed for your component to function

The installer installs these dependencies first

Example contents of `dependencies.yml`:

```yml
- skins/MonoBook
- extensions/EventLogging
```

As you can see above, your component, whether extension or skin, can have dependencies on other extensions/skins, and these will be installed when you install your component

### pages/ (optional)

If your component's manifest folder contains a `pages` folder, any page dump xml files in that folder will be imported when your component is installed

### docker-compose.yml (optional)

If your component needs additional containers, you can specify them in its own `docker-compose.yml`

See the Elastica [docker-compose.yml](extensions/Elastica/docker-compose.yml) for an example

Notice how the Elastica `docker-compose.yml` also specifies a couple values for the `mediawiki-web` container

This is allowed, of course, but try to keep such changes to core Mediawiki containers to a minimum - your component's `docker-compose.yml` should be mostly concerned with your component

### setup.SERVICE_NAME.sh (optional)

If your component's `docker-compose.yml` defines a service which needs its own setup commands to be run, you can add a `setup.SERVICE_NAME.sh` script to your component's manifest folder. When your component is installed, the setup script will be run in your service's container after the installer brings it up

## Installing components

## Install an extension

For installing an extension, you'd first add a folder for your extension to `extensions/`

You'd place the required and optional files inside your folder

Then you run:

```bash
./install extensions/YOUR_EXTENSION
```

## Install a skin

For installing a skin, you'd first add a folder for your skin to `skins/`

You'd place the required and optional files inside your folder

Then you run:

```bash
./install skins/YOUR_SKIN
```

## Activating a skin

After installing a skin you can this to activate it:

```bash
./make_skin_default YOUR_SKIN
```

Or you can use the `use_skin` convenience script to both install and activate your skin:

```bash
./use_skin YOUR_SKIN
```

## Installing multiple components at once

The `install` script can also be passed multiple components to install:

```bash
./install skins/MonoBook extensions/IPInfo
```

Or you can use the convenience script `install_all` to install every skin, every extension, or every component

```bash
./install_all skins
```

```bash
./install_all extensions
```

```bash
./install_all skins extensions
```

## Important component notes

- Do not use `composer install`, `npm install` or `npm ci` in your components' `setup.sh` files

  The installer takes care of this automatically if it sees your component contains `composer.json` / `package.json` / `package-lock.json`

  It also rebuilds localization caches after installations complete so no need to run `php maintenance/rebuildLocalisationCache.php`

- Ensure you name your component's folder the same way the extension or skin is named on Gerrit, this is because the installer clones your component from Gerrit using the name from this folder

# Testing

Run a variety of tests using the commands below

## Mediawiki parser

- Run parser tests

```bash
./run_parser_tests
```

## Mediawiki PHP

- Run PHP unit tests

```bash
./run_php_unit_tests
```

- Run PHP unit tests with a specific group

```bash
./run_php_unit_tests --group Cache
```

- Run PHP unit tests with a specific path

```bash
./run_php_unit_tests tests/phpunit/unit/includes/resourceloader/
```

## QUnit

- Run QUnit tests

```bash
./run_qunit
````

## Jest

- Run Jest tests

```bash
./run_jest
````

## Selenium (basic)

The `run_component_selenium_tests` script kicks off Selenium tests for your component via its `package.json` `selenium-test` script

This (`npm run selenium-test`) is the normal ingress point CI uses to trigger Selenium tests

- Run all tests in a specific extension

```bash
./install extensions/Echo
./run_component_selenium_tests extensions/Echo
```

- Run all tests in a specific skin

```bash
./install skins/MinervaNeue
./run_component_selenium_tests skins/MinervaNeue
```

## Selenium (advanced)

The `run_selenium_tests` script kicks off Selenium tests for your extension or skin via direct invocation of `wdio`

This ingress point allows for more fine-grain control of what tests gets run, also allowing for other `wdio` flags to be set, but it can occasionally have issues if a component depends on code in its `wdio.conf.js`, which this bypasses

### Mediawiki core

- List all core and extension test files and tests, can be used to customize the file and test parameters in the `run_selenium_tests` examples below

```bash
./list_selenium_tests
```

- Run a MediaWiki core test

```bash
./run_selenium_tests "tests/selenium/specs/page.js" "should be creatable"
```

- Run all tests in a specific MediaWiki core test file

```bash
./run_selenium_tests "tests/selenium/specs/page.js" ".*"
```

- Run all MediaWiki core tests

```bash
./run_selenium_tests
```

or

```bash
./run_selenium_tests "tests/selenium/**/specs/**/*.js" ".*"
```

### Mediawiki extensions

- Run a test in a specific extension

```bash
./install extensions/Echo
./run_selenium_tests "extensions/Echo/tests/selenium/specs/echo.js" "alerts and notices are visible"
```

- Run all tests in specific extension file

```bash
./install extensions/Echo
./run_selenium_tests "extensions/Echo/tests/selenium/specs/echo.js" ".*"
```

- Run all tests in a specific extension

```bash
./install extensions/Echo
./run_selenium_tests "extensions/Echo/tests/selenium/*specs/**/*.js" ".*"
```

- Run all tests in all extensions

```bash
./install_all extensions
./run_selenium_tests "extensions/*/tests/selenium/*specs/**/*.js" ".*"
```

### Mediawiki skins

- Run a test in a specific skin

```bash
./install skins/MinervaNeue
./run_selenium_tests "skins/MinervaNeue/tests/selenium/specs/references.js" "Opening a reference"
```

- Run all tests in specific skin file

```bash
./install skins/MinervaNeue
./run_selenium_tests "skins/MinervaNeue/tests/selenium/specs/references.js" ".*"
```

- Run all tests in specific skin

```bash
./install skins/MinervaNeue
./run_selenium_tests "skins/MinervaNeue/tests/selenium/*specs/**/*.js" ".*"
```

- Run all tests in all skins

```bash
./install_all skins
./run_selenium_tests "skins/*/tests/selenium/*specs/**/*.js" ".*"
```

### Advanced GLOB patterns

This [Glob Primer](https://github.com/isaacs/node-glob?tab=readme-ov-file#glob-primer) has details on more advanced pattern matching

For example, you could use `+` and `|` to run all skin and extension tests with one command:

```bash
./install_all skins extensions
./run_selenium_tests "+(skins|extensions)/*/tests/selenium/*specs/**/*.js" ".*"
```

You can also run all core, skin and extension tests with one command:

```bash
./install_all skins extensions
./run_selenium_tests "{+(skins|extensions)/*/,}tests/selenium/*specs/**/*.js" ".*"
```

### Overriding Selenium run log level

`./run_selenium_tests` supports an optional third parameter for setting the `logLevel`

Its default value is `error`, but can be changed to one of these:

( `trace` | `debug` | `info` | `warn` | `error` | `silent` ) see https://webdriver.io/docs/configurationfile/

For example, to use `debug` log level:

```bash
./run_selenium_tests "tests/selenium/specs/**/*.js" ".*" "debug"
```

### Overriding Selenium retries

You can use the `SELENIUM_RETRIES` env var to have Selenium retry failed tests:

```bash
SELENIUM_RETRIES=2 ./run_selenium_tests
```

Retries defaults to 0 if the env var is not used

### Overriding Selenium max instances

You can use the `SELENIUM_INSTANCES` env var to have Selenium run more than a single instance at once:

```bash
SELENIUM_INSTANCES=4 ./run_selenium_tests
```

Instances defaults to 1 if the env var is not used

## Quickstart

Quickstart's functionality is verified by a variety of tests found in `tests/`

Run all Quickstart tests:

```bash
./test_all
```

Run all tests in a specific Quickstart test file (handy for debugging):

```bash
./test tests/shellto_tests.sh
```

Run specific test(s) in a Quickstart test file:

```bash
./test tests/shell_tests.sh test_shellto_web test_shellto_web_interactive
```

# CI

The `ci` script is run for each commit / merge request:

```bash
./ci
```

It runs all Quickstart tests (via `test_all`) and reports the results

## Mediawiki components (skins/extensions) Selenium  

For each component manifest, do a `fresh_install` of Mediawiki, install the component, then run its Selenium tests:

```bash
./ci.components.selenium
```

This runs in a loop on a Horizon VPS configured with these cloud config [settings](vps/ci.components.selenium.md)

The results of these runs are available on [https://quickstart-ci-components.wmcloud.org](https://quickstart-ci-components.wmcloud.org)

If you want to run it locally, it takes a couple hours

By default it places its 3 output files in the `mediawiki-quickstart` folder:

- index.html      ( results chart )
- index.log       ( raw asci logs ) 
- index.log.html  ( html version of logs )

You can invoke it with an optional path override:
```bash
OUTPUT_PATH=/some/path ./ci.components.selenium
```

Once started, you can `tail -f index.log` in a separate terminal window to follow along live 

# Adding/overriding MediaWiki 'LocalSettings.php' values

To apply custom MediaWiki settings during `./fresh_install`, add a file to the `import-on-fresh-install/` folder such as:

`import-on-fresh-install/LocalSettings.#YOUR_DESCRIPTION#.php`

Files named according to that pattern will be included by MediaWiki's `LocalSettings.php`

You can use such files to override MediaWiki's `LocalSettings.php` settings

You can also override default component settings if needed

But keep in mind this is NOT the place to add default settings for extensions or skins - your component's [LocalSettings.php](#localsettingsphp-required) is the place for this

# Importing Mediawiki XML page dumps

When you run `./fresh_install`, page dump XML files found in [`import-on-fresh-install/pages/`](import-on-fresh-install/pages/) will be imported into the fresh MediaWiki instance

# Container Management

You can manage the MediaWiki containers using these commands

- Stops MediaWiki containers

```bash
./stop
```

- Starts MediaWiki containers

```bash
./start
```

- Restarts MediaWiki containers

```bash
./restart
```

- Stops and removes MediaWiki containers and files

```bash
./remove
```

# Container Shell Access

Get quick shell access to running MediaWiki containers with these commands

- Shell access to the MediaWiki container

```bash
./shellto m
```

- Shell access to the job runner container

```bash
./shellto j
```

- Shell access to the web container

```bash
./shellto w
```

- Shell access to the Selenium viewer container ("n" is for "NoVNC")

```bash
./shellto n
```

Note: after shelling into a container you can use the "bash" command so you can do things like use the up arrow to view previous commands you have run

If a command is specified, it is run in the specified container, `shellto` then returns to your host shell:

```bash
./shellto m ps aux                 # List processes in mediawiki container
./shellto w cat /etc/os-release    # Show OS info for web container
./shellto j pwd                    # Show working directory in jobrunner container
```

# Debugging

## VSCode

- Ensure the "PHP Debug" extension is installed

- Set breakpoints in your MediaWiki PHP files

- Start the debugger in VS Code (F5 or the "Start Debugging" button)

- Browse to the Mediawiki page executing your breakpoint code

- Execute this once in the browser's console:

```javascript
javascript:(function(){document.cookie="XDEBUG_SESSION=VSCODE;path=/";})();
```

# Miscellaneous

## Skip installation of the `Vector` skin on a fresh install

```bash
SKIP_SKIN=1 ./fresh_install
```

## Bypass all confirmations for removing and re-installing Mediawiki files and containers, but use with caution as this proceeds with these destructive actions without confirmation

```bash
FORCE=1 ./fresh_install
```

## Control the depth of git clones for MediaWiki and its components by setting the CLONE_DEPTH environment variable. If left off, a clone depth of 2 is performed by default, which is fast (and keeps Gerrit "git review" happy, which can complain if a repo's depth is 1)

```bash
CLONE_DEPTH=100 ./fresh_install  # Clone with depth of 100 commits
```

```bash
CLONE_DEPTH=0 ./fresh_install    # Full clone - really slow!
```

## See verbose console output when debugging installation issues

```bash
VERBOSE=1 ./fresh_install
```

## Clone repositories via `ssh` instead of `https`. Change `GIT_CLONE_BASE_URL` in `config` file. (Replace `username` with your username.)

```bash
GIT_CLONE_BASE_URL="ssh://username@gerrit.wikimedia.org:29418/mediawiki"
```

## Speed up installation by skipping any countdowns

```bash
SKIP_COUNTDOWN=1 ./fresh_install
```

## Skip opening `Special:Version` page after installation and skip opening VNC viewer when running Selenium tests

```bash
SILENT=1 ./fresh_install
```

## Specify branch for Mediawiki core installation

```bash
BRANCH="wmf/1.44.0-wmf.20" ./fresh_install
```

## Specify branch for component(s) installation

```bash
BRANCH="wmf/1.44.0-wmf.20" ./install extension/IPInfo skin/Monobook
```

## Skip rebuilding the localization cache after installing components (can save time but might cause UI issues). Can also be used with `fresh_install` since it uses the component installer to install the Vector skin

```bash
SKIP_LOCALIZATION_CACHE_REBUILD=1 ./install extensions/IPInfo
```

## Skip importing XML page dumps (can speed up installation when you don't need the page content)

```bash
SKIP_PAGE_IMPORT=1 ./fresh_install
```

## Apply Gerrit change refs during installation (for testing patches)

After cloning Mediawiki core (via `fresh_install`) or extension or skin repos (via `install`), Quickstart checks if they have any of the GERRIT_PATCHES you've optionally specified. If they do, Quickstart fetches and checks them out

```bash
GERRIT_PATCHES="refs/changes/94/1146994/6" ./fresh_install
```

You can also specify multiple patches separated by a space:

```bash
GERRIT_PATCHES="refs/changes/94/1146994/6 refs/changes/67/987654/2" ./install skins/Timeless extensions/AdvancedSearch extensions/Math
```

Gerrit patch numbers ( like `1146994` above ) are repo-specific, so it's safe to assume your patches will only be found / applied to intended repos

This approach is used because Quickstart's component installer also installs the dependencies of given components - ie you could do something like this, where `refs/changes/94/1234567/6` is a Mediawiki core patch, and `refs/changes/54/9876543/2` is a Elastica patch ( which gets installed implicitly when you install AdvancedSearch ):

```bash
GERRIT_PATCHES="refs/changes/94/1234567/6 refs/changes/54/9876543/2 ./install extensions/AdvancedSearch
```

# MySQL

Quickstart uses SQLite by default

To use MySQL you have a few options

In the MySQL example below the relevant environment variables are exported to the shell session so they don't have to be repeated for both `fresh_install` and `install` commands

Remember that exported env vars persist in your shell session until you start a new shell window or reload the session

You could also add these env var exports to Quickstart's `config` or your `~/.bashrc` or `~/.zshrc` (on MacOS) file so they'd get automatically used by all calls to `fresh_install` and `install`

```bash
# Let Quickstart know you want to use MySQL
export MW_DBTYPE=mysql

# MW_DBSERVER can one of the following three options
# 1: a network address
export MW_DBSERVER=#YOUR_MYSQL_SERVER_LOCATION#
# 2: 'host.docker.internal' if the MySQL server is hosted directly on the Docker host machine
export MW_DBSERVER=host.docker.internal
# 3: 'mediawiki-mysql-1' if you want to use Quickstart's built-in MySQL container
export MW_DBSERVER=mediawiki-mysql-1
  # If using Quickstart's built-in MySQL container, you must also use the following COMPOSE_PROFILES to instruct docker to start the mysql container in addition to the 'default' containers. Reminder: only use this if 'MW_DBSERVER=mediawiki-mysql-1' 
  export COMPOSE_PROFILES="default,mysql"

export MW_DBNAME=my_wiki
export MW_DBUSER=root
export MW_DBPASS=""
export MW_DBPORT=3306
./fresh_install
./install extensions/IPInfo
```

## MySQL backup and restoration

- When using Quickstart's built-in MySQL container, you can save a zipped backup of the "mysql-data" folder to the "mysql-backups" folder (the backup file will have the timestamp in its name, ie 'mysql-backups/mysql.2025-02-12_16-49-46-0600-CST.gz')
```bash
./mysql_backup
```

- You can also restore a zipped backup from "mysql-backups" to "mysql-data"
```bash
./mysql_restore_from_backup mysql-backups/mysql.2025-02-12_16-49-46-0600-CST.gz
```

- If you want a backup restored when you run `./fresh_install` place the backup here naming it 'mysql.backup.gz':
```bash
./import-on-fresh-install/mysql.backup.gz
```

# Bug Reporting

Open a Phabricator task [here](https://phabricator.wikimedia.org/maniphest/task/edit/form/default/?title=&description=Bug+Description&projects[]=mediawiki-quickstart) to report issues and make feature requests

# Contributions

Merge requests are welcome

Please ensure your changes don't add dependencies on the host or negatively impact `fresh_install` quickness

It's a good idea to run the `./ci` script locally too to ensure all tests pass with your changes