Quickly spin up a MediaWiki instance.

## Installation 

Ensure you have [Docker](https://www.docker.com/products/docker-desktop) installed.

Clone the repo:

    git clone https://gitlab.wikimedia.org/mhurd/mediawiki-docker-make.git

## Usage

Switch to the `mediawiki-docker-make` directory:

    cd ~/mediawiki-docker-make

Now you can spin up the MediaWiki with the *make* command:
-   ```
    make
     ```
    Fetches the latest MediaWiki (into `~/mediawiki-docker-make/mediawiki/`) and spins up a Docker container using it

You can stop, start, restart or remove the containers with these commands:
-   ```
    make stop
     ```
    Stops mediawiki containers

-   ```
    make start
     ```
    Start mediawiki containers

-   ```
    make restart
     ```
    Restarts mediawiki containers

-   ```
    make remove
     ```
    Stops and removes mediawiki containers and files

Get quick Bash shell access to running containers with these commands:
-   ```
    make bash_mw
     ```
    Bash access to the mediawiki container

-   ```
    make bash_jr
     ```
    Bash access to the job runner container

-   ```
    make bash_wb
     ```
    Bash access to the web container

Quickly switch skins with these commands (easy to add more if needed):

-   ```
    make use_vector_skin
     ```
    Fetch and switch to the Vector skin

-   ```
    make use_minervaneue_skin
     ```
    Fetch and switch to the Minerva Neue skin
    
-   ```
    make use_timeless_skin
     ```
    Fetch and switch to the Timeless skin

-   ```
    make use_monobook_skin
     ```
    Fetch and switch to the MonoBook skin

Run tests with these commands:

-   ```
    make run_parser_tests
     ```
    Run parser tests

-   ```
    make run_php_unit_tests
     ```
    ```
    make run_php_unit_tests testgroup=Cache
     ```
    ```
    make run_php_unit_tests testpath=unit/includes/resourceloader/
     ```
    Run PHP unit tests