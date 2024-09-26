Quickly spin up a MediaWiki instance with Docker

Easy skin and extension configuration via manifest yml files

Test running including Selenium tests you can watch as they execute

# Prerequisites 

- [Docker](https://www.docker.com/products/docker-desktop) installed

# Installation

1. Clone the repository
    ```bash
    git clone https://gitlab.wikimedia.org/mhurd/mediawiki-quickstart.git
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

- You can also do a fresh install bypassing all confirmations for removing and re-installing Mediawiki files and containers, but use with caution as this proceeds with these destructive actions without confimation
    ```bash
    FORCE=1 ./fresh_install
    ```

# Optional

## Component management (installing skins/extensions)

Quickstart considers skins and extensions to be "components"

### Component manifests

A folder-based manifest format is used to definine how extensions and skins are installed

You can see examples in the `~/mediawiki-quickstart/manifests/` directory

`manifests` contains `extensions` and `skins` sub-directories

In these you will see one directory per extension/skin:

```
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

### Component manifest folder required file

Inside each component's folder a single file is required:

`LocalSettings.php`

In this file you put whatever settings your component needs to load/run it

QuickStart's component installer links your component's `LocalSettings.php` to Mediawiki's `LocalSettings.php` by adding an include to the latter

The installer automatically clones your components repo so you don't have to

### Component manifest folder optional files/folders

Components also support the following optional files/folders:

#### setup.sh

`setup.sh` is executed by the installer after your component's repo is cloned

This is where you can put any shell scripting that needs to execute to set up your component

It is executed relative to mediawiki's directory in the mediawiki container - i.e. `pwd` placed in your `setup.sh` will output `/var/www/html/w` 

#### dependencies.yml

This is where you can define other components that must be installed for your component to function

The installer installs these dependencies first

Example contents of `dependencies.yml`:

```
- skins/MonoBook
- extensions/EventLogging
```

As you can see above, your component, whether extension or skin, can have depenencies on other extensions/skins, and these will be installed when you install your component

#### pages/

If your component's manifest folder contains a `pages` folder, any page dump xml files in that folder will be imported when your component is installed

### Installing components

### Install an extension

For installing an extension, you'd first add a folder for your extension to `manifests/extensions`

You'd place the required and optional files inside your folder

Then you run:

`./install extensions/YOUR_EXTENSION`

### Install a skin

For installing a skin, you'd first add a folder for your skin to `manifests/skins`

You'd place the required and optional files inside your folder

Then you run:

`./install skins/YOUR_SKIN`

### Activating a skin

After installing a skin you can this to activate it:

`./make_skin_default YOUR_SKIN`

Or you can use the `use_skin` convenience script to both install and activate your skin:

`./use_skin YOUR_SKIN`

### Installing multiple components at once

The `install` script can also be passed multiple components to install:

`./install skins/MonoBook extensions/IPInfo`

Or you can use the convenience script `install_all` to install every skin, every extension, or every component

`./install_all skins`

`./install_all extensions`

`./install_all skins extensions`

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

    or
    
    ./run_selenium_tests "tests/selenium/specs/**/*.js" ".*"
    ```

- Run a test in a specific extension
    ```bash
    ./extensions/install Echo
    ./run_selenium_tests "extensions/Echo/tests/selenium/specs/echo.js" "alerts and notices are visible"
    ```
 
- Run all tests in specific extension file
    ```bash
    ./extensions/install Echo
    ./run_selenium_tests "extensions/Echo/tests/selenium/specs/echo.js" ".*"
    ```

- Run all tests in a specific extension
    ```bash
    ./extensions/install Echo
    ./run_selenium_tests "extensions/Echo/tests/selenium/*specs/**/*.js" ".*"
    ```

- Run all tests in all extensions
    ```bash
    ./extensions/install_all
    ./run_selenium_tests "extensions/*/tests/selenium/*specs/**/*.js" ".*"
   ```

#### Overriding Selenium run log level

`./run_selenium_tests` supports an optional third parameter for setting the `logLevel`

Its default value is `error`, but can be changed to one of these: 

( `trace` | `debug` | `info` | `warn` | `error` | `silent` ) see https://webdriver.io/docs/configurationfile/

For example, to use `debug` log level:

```bash
./run_selenium_tests "tests/selenium/specs/**/*.js" ".*" "debug"
```

## Custom MediaWiki 'LocalSettings'

To apply custom MediaWiki settings during `./fresh_install`, edit [`import-on-fresh-install/LocalSettings.extra.php`](import-on-fresh-install/LocalSettings.extra.php)

This file will be included by MediaWiki's `LocalSettings.php`

Keep in mind this is not the place to add settings for extensions - the extension yml [format](#extension-management) has a `configuration` key for such settings

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
    ```sh
    ./shellto m
    ```

- Shell access to the job runner container
    ```sh
    ./shellto j
    ```

- Shell access to the web container
    ```sh
    ./shellto w
    ```

- Shell access to the Selenium viewer container ("n" is for "NoVNC")
    ```sh
    ./shellto n
    ```

Note: after shelling into a container you can use the "bash" command so you can do things like use the up arrow to view previous commands you have run

## Miscellaneous

- If you don't want the `Vector` skin installed by default you can use this env var when you do a fresh install
    ```bash
    SKIP_SKIN=1 ./fresh_install
    ```
