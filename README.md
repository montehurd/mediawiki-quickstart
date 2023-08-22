Quickly spin up a MediaWiki instance with Docker

Easy skin and extension configuration via manifest files

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

## Skin Management

### Switch skin:

- Fetch and switch to the Vector skin:
    ```bash
    ./mw use_vector_skin
    ```

- Fetch and switch to the Minerva Neue skin:
    ```bash
    ./mw use_minervaneue_skin
    ```

- Fetch and switch to the Timeless skin:
    ```bash
    ./mw use_timeless_skin
    ```

- Fetch and switch to the MonoBook skin:
    ```bash
    ./mw use_monobook_skin
    ```

### Add skin:

Look at the skin manifest files in `~/mediawiki-quickstart/skins/manifests`

Copy one of them and name it for your skin and edit it to use your skin's settings

- Then you can fetch and switch to your skin:
    ```bash
    ./mw use_skin #your_skin_filename_without_extension#
    ```

## Testing

Run tests with these commands:

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

- Run Selenium tests:
    ```bash
    ./mw run_selenium_tests
    ```

- Run a specific Selenium test:
    ```bash
    ./mw run_selenium_test
    ```

- Run a specific Selenium test file:
    ```bash
    ./mw run_selenium_test_file
    ```

- Run Selenium tests with wildcard:
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

## Manage containers

You can manage the MediaWiki containers using these commands:

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

## Shell Access

Get quick Bash shell access to running containers with these commands:

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