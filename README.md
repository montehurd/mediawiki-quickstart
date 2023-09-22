Quickly spin up a MediaWiki instance with Docker

Easy skin and extension configuration via manifest yml files

Test running including Selenium tests you can watch as they execute

# Prerequisites 

- [Docker](https://www.docker.com/products/docker-desktop) installed

# Installation

1. Clone the repository:
    ```bash
    git clone https://gitlab.wikimedia.org/mhurd/mediawiki-quickstart.git
    ```

2. Navigate to the repository directory:
    ```bash
    cd ~/mediawiki-quickstart
    ```

# Usage

## Fetch, configure and start MediaWiki

- Fetches the latest MediaWiki (into `~/mediawiki-quickstart/mediawiki/`) and spins up its Docker containers:
    ```bash
    ./mw fresh_install
    ```

# Optional

## Skin Management

### Switching skins:

`use_skin` fetches and switches to a skin and refreshes the browser to show the skin in use

It's safe to call more than once for a given skin, so you can use it to quickly toggle between skins

- Vector skin:
    ```bash
    ./mw use_skin vector
    ```

- Minerva Neue skin:
    ```bash
    ./mw use_skin minervaneue
    ```

- Timeless skin:
    ```bash
    ./mw use_skin timeless
    ```

- MonoBook skin:
    ```bash
    ./mw use_skin monobook
    ```

### Adding more skins:

Look at the skin manifest yml files in `~/mediawiki-quickstart/skins/manifests`

Copy one of them and rename it for your skin and edit it to use your skin's settings

- Then you can fetch and switch to your skin:
    ```bash
    ./mw use_skin #your_skin_filename_without_extension#
    ```

- You can also call the skin installers directly:
    ```bash
    ./skins/installer.sh install #one_or_more_extensionless_skin_filename_separated_by_spaces#
    ```

    ```bash
    ./skins/installer.sh install_all
    ```

Skin installers are also safe to call more than once for a given skin

### Skin yml example:

- Here's an example skin manifest yml ( `~/mediawiki-quickstart/skins/manifests/Vector.yml` )
    ```yaml
    name: Vector
    repository: https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git
    branch: master
    wfLoadSkin: Vector
    wgDefaultSkin: vector
    ```

    Note: all keys in the above example are required. For skins there are no optional keys

## Extension Management

- Install one or more extensions for which manifest files exist in `~/mediawiki-quickstart/extensions/manifests`:
    ```bash
    ./extensions/installer.sh install Echo
    ```

    ```bash
    ./extensions/installer.sh install Echo IPInfo
    ```

- Install all extensions for which manifest files exist in `~/mediawiki-quickstart/extensions/manifests`:
    ```bash
    ./extensions/installer.sh install_all
    ```

### Adding more extensions:

Look at the extension manifest yml files in `~/mediawiki-quickstart/extensions/manifests`

Copy one of them and rename it for your extension and edit it to use your extension's settings

Then use the `install` command above to install it

### Extension yml examples:

- Here's an example of a minimal extension manifest yml ( `~/mediawiki-quickstart/skins/manifests/IPInfo.yml` )
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

    Note: all keys in the above example are required. For extensions the following keys are optional:
    - `dependencies`
    - `bash`


- Here's an example extension manifest yml using the optional `bash` key ( `~/mediawiki-quickstart/skins/manifests/GlobalBlocking.yml` )
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

- Here's an example extension manifest yml using the optional `dependencies` key ( `~/mediawiki-quickstart/skins/manifests/CodeMirror.yml` )
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

## Testing

Run a variety of tests using the commands below

### Parser

- Run parser tests:
    ```bash
    ./mw run_parser_tests
    ```

### PHP

- Run PHP unit tests:
    ```bash
    ./mw run_php_unit_tests
    ```

- Run PHP unit tests with a specific group:
    ```bash
    ./mw run_php_unit_tests testgroup=Cache
    ```

- Run PHP unit tests with a specific path:
    ```bash
    ./mw run_php_unit_tests testpath=unit/includes/resourceloader/
    ```

### Selenium

These functions provide examples you can examine and customize if needed

- Run MediaWiki core Selenium tests:
    ```bash
    ./mw run_selenium_tests
    ```

- Run a specific MediaWiki core Selenium test:
    ```bash
    ./mw run_selenium_test
    ```

- Run all tests in a specific MediaWiki core Selenium test file:
    ```bash
    ./mw run_selenium_test_file
    ```

- Run MediaWiki core Selenium tests with wildcard:
    ```bash
    ./mw run_selenium_test_wildcard
    ```

- Run Selenium tests for installed extensions:
    ```bash
    ./mw run_selenium_extensions_tests
    ```

- Run Selenium tests for a specific extension:
    ```bash
    ./mw run_selenium_extension_tests
    ```

- Run Selenium test for a specific extension:
    ```bash
    ./mw run_selenium_extension_test
    ```

## Container Management

You can manage the MediaWiki containers using these commands

- Stops MediaWiki containers:
    ```bash
    ./mw stop
    ```

- Starts MediaWiki containers:
    ```bash
    ./mw start
    ```

- Restarts MediaWiki containers:
    ```bash
    ./mw restart
    ```

- Stops and removes MediaWiki containers and files:
    ```bash
    ./mw remove
    ```

## Container Shell Access

Get quick Bash shell access to running containers with these commands

- Bash access to the MediaWiki container:
    ```bash
    ./mw bash_mw
    ```

- Bash access to the job runner container:
    ```bash
    ./mw bash_jr
    ```

- Bash access to the web container:
    ```bash
    ./mw bash_wb
    ```