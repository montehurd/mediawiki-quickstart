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

## Skin Management

### Switching skins

`use_skin` fetches and switches to a skin and refreshes the browser to show the skin in use

It's safe to call more than once for a given skin, so you can use it to quickly toggle between skins

- Vector skin
    ```bash
    ./use_skin vector
    ```

- Minerva Neue skin
    ```bash
    ./use_skin minervaneue
    ```

- Timeless skin
    ```bash
    ./use_skin timeless
    ```

- MonoBook skin
    ```bash
    ./use_skin monobook
    ```

### Adding more skins

Look at the skin manifest yml files in `~/mediawiki-quickstart/skins/manifests`

Copy one of them and rename it for your skin and edit it to use your skin's settings

- Then you can fetch and switch to your skin
    ```bash
    ./use_skin #your_skin_filename_without_extension#
    ```

- You can also call the skin installers directly
    ```bash
    ./skins/install Vector
    ```

    ```bash
    ./skins/install Vector Timeless
    ```

    ```bash
    ./skins/install_all
    ```

Skin installers are also safe to call more than once for a given skin

### Skin yml example

- Example skin manifest yml ( [~/mediawiki-quickstart/skins/manifests/Vector.yml](./skins/manifests/Vector.yml) )
    ```yaml
    name: Vector
    repository: https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git
    branch: master
    wfLoadSkin: Vector
    wgDefaultSkin: vector
    ```

    Note: all keys in the above example are required. For skins there are no optional keys

### Skin yml keys

- `name` required

    Skin name
- `repository` required

    Skin git repo url
- `branch` required

    Skin branch to use
- `wfLoadSkin` required

    Skin key value pair which will be added to LocalSettings.php
- `wgDefaultSkin` required

    Skin key value pair which will be added to LocalSettings.php

## Extension Management

- Install one or more extensions for which manifest files exist in `~/mediawiki-quickstart/extensions/manifests`
    ```bash
    ./extensions/install Echo
    ```

    ```bash
    ./extensions/install Echo IPInfo
    ```

- Install all extensions for which manifest files exist in `~/mediawiki-quickstart/extensions/manifests`
    ```bash
    ./extensions/install_all
    ```

### Adding more extensions

Look at the extension manifest yml files in `~/mediawiki-quickstart/extensions/manifests`

Copy one of them and rename it for your extension and edit it to use your extension's settings

Then use the `install` command above to install it

### Extension yml examples

- Example of a minimal extension manifest yml ( [~/mediawiki-quickstart/extensions/manifests/IPInfo.yml](./extensions/manifests/IPInfo.yml) )
    ```yaml
    name: IPInfo
    repository: https://gerrit.wikimedia.org/r/mediawiki/extensions/IPInfo
    configuration: |
      wfLoadExtension( 'IPInfo' );
      $wgGroupPermissions['*']['ipinfo'] = true;
      $wgGroupPermissions['*']['ipinfo-view-basic'] = true;
      $wgGroupPermissions['*']['ipinfo-view-full'] = true;
      $wgGroupPermissions['*']['ipinfo-view-log'] = true;
    ```

    Note: all keys in the above example are required. For extensions the following keys are optional
    - `dependencies`
    - `bash`

- Example extension manifest yml using the optional `bash` key ( [~/mediawiki-quickstart/extensions/manifests/GlobalBlocking.yml](./extensions/manifests/GlobalBlocking.yml) )
    ```yaml
    name: GlobalBlocking
    repository: https://gerrit.wikimedia.org/r/mediawiki/extensions/GlobalBlocking
    configuration: |
      wfLoadExtension( 'GlobalBlocking' );
      $wgGlobalBlockingDatabase = 'globalblocking';
      $wgApplyGlobalBlocks = true;
      $wgGlobalBlockingBlockXFF = true;
    bash: |
      apt update
      apt install sqlite3
      sqlite3 cache/sqlite/globalblocking.sqlite < extensions/GlobalBlocking/sql/sqlite/tables-generated-globalblocks.sql
   
    ```

- Example extension manifest yml using the optional `dependencies` key ( [~/mediawiki-quickstart/extensions/manifests/CodeMirror.yml](./extensions/manifests/CodeMirror.yml) )
    ```yaml
    name: CodeMirror
    repository: https://gerrit.wikimedia.org/r/mediawiki/extensions/CodeMirror
    dependencies:
      - VisualEditor
    configuration: |
      wfLoadExtension( 'CodeMirror' );
      # This configuration enables syntax highlighting by default for all users
      $wgDefaultUserOptions['usecodemirror'] = 1;   
    ```

### Extension yml keys

- `name` required

    Extension name
- `repository` required

    Extension git repo url
- `configuration` required

    Extension configuration php which will be added to LocalSettings.php
- `bash` optional

    Extension scripting to execute on installation
- `dependencies` optional

    Other extension yml file(s) to install when installing this extension

### Important Extension manifest yml note

- Do not use `composer install` or `npm install` in your extension `bash` key's value

  The extension installer script takes care of this automatically if it sees your extension contains `composer.json` / `package.json`

  It also rebuilds localization caches when extension(s) are installed, so no need to run `php maintenance/rebuildLocalisationCache.php`

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
    ./run_php_unit_test_path unit/includes/resourceloader/
    ```

### Selenium

These functions provide examples you can examine and customize if needed

- Run MediaWiki core Selenium tests
    ```bash
    ./run_selenium_tests
    ```

- Run a specific MediaWiki core Selenium test
    ```bash
    ./run_selenium_test
    ```

- Run all tests in a specific MediaWiki core Selenium test file
    ```bash
    ./run_selenium_test_file
    ```

- Run MediaWiki core Selenium tests with wildcard
    ```bash
    ./run_selenium_test_wildcard
    ```

- Run Selenium tests for installed extensions
    ```bash
    ./run_selenium_extensions_tests
    ```

- Run Selenium tests for a specific extension
    ```bash
    ./run_selenium_extension_tests
    ```

- Run Selenium test for a specific extension
    ```bash
    ./run_selenium_extension_test
    ```

- List Selenium core and extension tests
    ```bash
    ./list_selenium_tests
    ```

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

Get quick Bash shell access to running MediaWiki containers with these commands

- Bash access to the MediaWiki container
    ```bash
    ./shellto m
    ```

- Bash access to the job runner container
    ```bash
    ./shellto j
    ```

- Bash access to the web container
    ```bash
    ./shellto w
    ```
