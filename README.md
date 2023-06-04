# MediaWiki Docker Quickstart

Quickly spin up a MediaWiki instance with Docker.

## Prerequisites 

- [Docker](https://www.docker.com/products/docker-desktop) installed.

## Installation

1. Clone the repository:
    ```bash
    git clone https://gitlab.wikimedia.org/mhurd/mediawiki-docker-make.git
    ```

2. Navigate to the repository directory:
    ```bash
    cd ~/mediawiki-docker-make
    ```

## Usage

### Start MediaWiki

- Fetches the latest MediaWiki (into `~/mediawiki-docker-make/mediawiki/`) and spins up a Docker container using it:
    ```bash
    make
    ```

### Manage Containers

You can manage the MediaWiki containers using these commands:

- Stops MediaWiki containers:
    ```bash
    make stop
    ```

- Starts MediaWiki containers:
    ```bash
    make start
    ```

- Restarts MediaWiki containers:
    ```bash
    make restart
    ```

- Stops and removes MediaWiki containers and files:
    ```bash
    make remove
    ```

### Shell Access

Get quick Bash shell access to running containers with these commands:

- Bash access to the MediaWiki container:
    ```bash
    make bash_mw
    ```

- Bash access to the job runner container:
    ```bash
    make bash_jr
    ```

- Bash access to the web container:
    ```bash
    make bash_wb
    ```

### Skin Management

Quickly switch skins with these commands:

- Fetch and switch to the Vector skin:
    ```bash
    make use_vector_skin
    ```

- Fetch and switch to the Minerva Neue skin:
    ```bash
    make use_minervaneue_skin
    ```

- Fetch and switch to the Timeless skin:
    ```bash
    make use_timeless_skin
    ```

- Fetch and switch to the MonoBook skin:
    ```bash
    make use_monobook_skin
    ```

### Testing

Run tests with these commands:

- Run parser tests:
    ```bash
    make run_parser_tests
    ```

- Run PHP unit tests:
    ```bash
    make run_php_unit_tests
    ```

- Run PHP unit tests with a specific group:
    ```bash
    make run_php_unit_tests testgroup=Cache
    ```

- Run PHP unit tests with a specific path:
    ```bash
    make run_php_unit_tests testpath=unit/includes/resourceloader/
    ```

- Run Selenium tests:
    ```bash
    make run_selenium_tests
    ```

- Run a specific Selenium test:
    ```bash
    make run_selenium_test
    ```

- Run a specific Selenium test file:
    ```bash
    make run_selenium_test_file
    ```

- Run Selenium tests with wildcard:
    ```bash
    make run_selenium_test_wildcard
    ```
