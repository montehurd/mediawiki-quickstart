# mediawiki-quickstart

Quickly spin up a MediaWiki instance with Docker

Easy skin and extension management via "component" manifest folders

Test running including Selenium tests you can watch as they execute

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop) installed

## Installation

1. Clone the repository

```bash
git clone https://gitlab.wikimedia.org/mhurd/mediawiki-quickstart.git
```

2. Navigate to the repository directory

```bash
cd ~/mediawiki-quickstart
```

## Usage

### Fetch, configure and start MediaWiki

- Fetches the latest MediaWiki (into `~/mediawiki-quickstart/mediawiki/`) and spins up its Docker containers

```bash
./fresh_install
```

## Component management (installing skins/extensions)

Quickstart considers skins and extensions to be "components"

### Component manifests

A folder-based manifest format is used to define how extensions and skins are installed

You can see examples in the `~/mediawiki-quickstart/manifests/` directory

`manifests` contains `extensions` and `skins` sub-directories

In these you will see one directory per extension/skin:

```text
manifests/
  |--extensions/
  |----IPInfo/
  |----Math/
  |----VisualEditor/
  ...
  |--skins/
  |----MonoBook/
  |----Vector/
  |----Timeless/
  ...
```

### Component manifest folder contents

```text
manifests/
  |--extensions/
  |----IPInfo/
  |------LocalSettings.php  (required)
  |------setup.sh           (optional)
  |------dependencies.yml    (optional)
  |------pages/             (optional)
  ...
  |--skins/
  |----MonoBook/
  |------LocalSettings.php  (required)
  |------setup.sh           (optional)
  |------dependencies.yml    (optional)
  |------pages/             (optional)
  ...
```

#### LocalSettings.php (required)

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

#### setup.sh (optional)

`setup.sh` is executed by the installer after your component's repo is cloned

This is where you can put any shell scripting that needs to execute to set up your component

It is executed relative to mediawiki's directory in the mediawiki container - i.e. `pwd` placed in your `setup.sh` will output `/var/www/html/w`

#### dependencies.yml (optional)

This is where you can define other components that must be installed for your component to function

The installer installs these dependencies first

Example contents of `dependencies.yml`:

```yml
- skins/MonoBook
- extensions/EventLogging
```

As you can see above, your component, whether extension or skin, can have dependencies on other extensions/skins, and these will be installed when you install your component

#### pages/ (optional)

If your component's manifest folder contains a `pages` folder, any page dump xml files in that folder will be imported when your component is installed

### Installing components

### Install an extension

For installing an extension, you'd first add a folder for your extension to `manifests/extensions`

You'd place the required and optional files inside your folder

Then you run:

```bash
./install extensions/YOUR_EXTENSION
```

### Install a skin

For installing a skin, you'd first add a folder for your skin to `manifests/skins`

You'd place the required and optional files inside your folder

Then you run:

```bash
./install skins/YOUR_SKIN
```

### Activating a skin

After installing a skin you can this to activate it:

```bash
./make_skin_default YOUR_SKIN
```

Or you can use the `use_skin` convenience script to both install and activate your skin:

```bash
./use_skin YOUR_SKIN
```

### Installing multiple components at once

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

### Important component notes

- Do not use `composer install`, `npm install` or `npm ci` in your components' `setup.sh` files

  The installer takes care of this automatically if it sees your component contains `composer.json` / `package.json` / `package-lock.json`

  It also rebuilds localization caches after installations complete so no need to run `php maintenance/rebuildLocalisationCache.php`

- Ensure you name your component's folder the same way the extension or skin is named on Gerrit, this is because the installer clones your component from Gerrit using the name from this folder

## Testing

Run a variety of tests using the commands below

### Parser

- Run parser tests

```bash
./run_parser_tests
```

### PHP

- Run PHP unit tests

```bash
./run_php_unit_tests
```

- Run PHP unit tests with a specific group

```bash
./run_php_unit_test_group Cache
```

- Run PHP unit tests with a specific path

```bash
./run_php_unit_test_path tests/phpunit/unit/includes/resourceloader/
```

### Selenium

#### Core

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

#### Extensions

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

#### Skins

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

#### Advanced GLOB patterns

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

#### Overriding Selenium run log level

`./run_selenium_tests` supports an optional third parameter for setting the `logLevel`

Its default value is `error`, but can be changed to one of these:

( `trace` | `debug` | `info` | `warn` | `error` | `silent` ) see https://webdriver.io/docs/configurationfile/

For example, to use `debug` log level:

```bash
./run_selenium_tests "tests/selenium/specs/**/*.js" ".*" "debug"
```

#### Overriding Selenium retries

You can use the `SELENIUM_RETRIES` env var to have Selenium retry failed tests:

```bash
SELENIUM_RETRIES=2 ./run_selenium_tests
```

Retries defaults to 0 if the env var is not used

#### Overriding Selenium max instances

You can use the `SELENIUM_INSTANCES` env var to have Selenium run more than a single instance at once:

```bash
SELENIUM_INSTANCES=4 ./run_selenium_tests
```

Instances defaults to 1 if the env var is not used

## Custom MediaWiki 'LocalSettings'

To apply custom MediaWiki settings during `./fresh_install`, edit [`import-on-fresh-install/LocalSettings.extra.php`](import-on-fresh-install/LocalSettings.extra.php)

This file will be included by MediaWiki's `LocalSettings.php`

Keep in mind this is not the place to add settings for extensions or skins - your component's [LocalSettings.php](#localsettingsphp-required) is the place for this

## Importing Mediawiki XML page dumps

When you run `./fresh_install`, page dump XML files found in [`import-on-fresh-install/pages/`](import-on-fresh-install/pages/) will be imported into the fresh MediaWiki instance

## Container Management

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

## Container Shell Access

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

You can also execute commands directly without entering a shell:

```bash
./shellto w cat /etc/os-release    # Show OS info for web container
./shellto j pwd                    # Show working directory in jobrunner container
./shellto m ps aux                 # List processes in mediawiki container
```

Each command runs in the specified container and returns to your host shell.

## Miscellaneous

- Skip installation of the `Vector` skin on a fresh install

```bash
SKIP_SKIN=1 ./fresh_install
```

- Bypass all confirmations for removing and re-installing Mediawiki files and containers, but use with caution as this proceeds with these destructive actions without confirmation

```bash
FORCE=1 ./fresh_install
```

- Control the depth of git clones for MediaWiki and its components by setting the CLONE_DEPTH environment variable. If left off, a clone depth of 2 is performed by default, which is fast (and keeps Gerrit "git review" happy, which can complain if a repo's depth is 1)

```bash
CLONE_DEPTH=100 ./fresh_install  # Clone with depth of 100 commits
```

```bash
CLONE_DEPTH=0 ./fresh_install    # Full clone - really slow!
```

- See verbose console output when debugging installation issues

```bash
VERBOSE=1 ./fresh_install
```

- Clone repositories via `ssh` instead of `https`. Change `GIT_CLONE_BASE_URL` in `config` file. (Replace `username` with your username.)

```bash
GIT_CLONE_BASE_URL="ssh://username@gerrit.wikimedia.org:29418/mediawiki"
```

- Speed up installation by skipping any countdowns

```bash
SKIP_COUNTDOWN=1 ./fresh_install
```

- Skip opening `Special:Version` page after installation
- Skip opening VNC viewer when running Selenium tests

```bash
SILENT=1 ./fresh_install
```
