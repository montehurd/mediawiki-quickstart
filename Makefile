SHELL := /bin/bash

# This file is used to spin up a basic dockerized mediawiki instance on your local machine.
# Comments above the make commands below explain their usage.
# 
# For general info on Makefiles see: https://makefiletutorial.com but this Makefile is really
# just a convenient way to run some commands via simple "make" shortcuts. For a similar
# example see: https://github.com/graphql-python/graphene/blob/master/docs/Makefile
# Note: "fresh" here does not reference the excellent "freshnode" container

makefile_dir = $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
mediawiki_dir = "$(makefile_dir)/mediawiki"
mediawiki_port=8080

define MW_ENV
MW_DOCKER_PORT=$(mediawiki_port)
MW_DOCKER_UID=$(id -u)
MW_DOCKER_GID=$(id -g)
MEDIAWIKI_USER=Admin
MEDIAWIKI_PASSWORD=dockerpass
XDEBUG_ENABLE=true
XHPROF_ENABLE=true
XDEBUG_CONFIG=''
endef
export MW_ENV

# "make freshinstall" (or just "make") fetches, installs and runs a basic mediawiki container. Mediawiki gets saved in a "mediawiki" directory in the parent directory of the Makefile.
.DEFAULT: freshinstall
.PHONY: freshinstall
freshinstall:
	make stop
	make remove
	make prepare
	make start

.PHONY: prepare
prepare:
	@mkdir $(mediawiki_dir); \
	cd $(mediawiki_dir); \
	git clone https://gerrit.wikimedia.org/r/mediawiki/core.git . --depth=1; \
	echo "$$MW_ENV" > .env;
	-cp ./docker-compose.override.yml $(mediawiki_dir)/docker-compose.override.yml;

# "make remove" stops and removes mediawiki containers and files.
.PHONY: remove
remove:
	-@if [ -d "$(mediawiki_dir)" ]; then \
		read -p "Are you sure you want to delete mediawiki containers and EVERYTHING in \"$(mediawiki_dir)\" (y/n)? " -n 1 -r; \
		echo ; \
		if [ "$$REPLY" = "y" ]; then \
			cd $(mediawiki_dir); \
			docker compose down; \
			rm -rf $(mediawiki_dir); \
			rm $(makefile_dir)/runonce; \
		fi; \
	fi

# "make stop" stops mediawiki containers.
.PHONY: stop
stop:
	-@cd $(mediawiki_dir); \
	docker compose stop

# "make start" start mediawiki containers.
.PHONY: start
start: $(makefile_dir)/runonce
	@is_running=$$($(makefile_dir)/utility.sh is_container_running "mediawiki-mediawiki-1"); \
	if [ "$$is_running" = false ]; then \
		cd $(mediawiki_dir); \
		docker compose up -d; \
		sleep 1; \
	fi; \
	cd $(makefile_dir); \
	./utility.sh wait_until_url_available $(special_version_url); \
	make openspecialversionpage;

$(makefile_dir)/runonce:
	-@cd $(mediawiki_dir); \
	docker compose up -d; \
	docker compose exec mediawiki composer update; \
	docker compose exec mediawiki bash /docker/install.sh; \
	sleep 2; \
	cd $(makefile_dir); \
	touch runonce; \
	make usevectorskin skipopenspecialversionpage=true;

# "make restart" restarts mediawiki containers.
.PHONY: restart
restart:
	make stop
	make start

# "make bashmw" for bash access to the mediawiki container.
.PHONY: bashmw
bashmw:
	cd $(mediawiki_dir); \
	docker compose exec mediawiki bash

# "make bashjr" for bash access to the job runner container.
.PHONY: bashjr
bashjr:
	cd $(mediawiki_dir); \
	docker compose exec mediawiki-jobrunner bash

# "make bashwb" for bash access to the web container.
.PHONY: bashwb
bashwb:
	cd $(mediawiki_dir); \
	docker compose exec mediawiki-web bash

.PHONY: usevectorskin
usevectorskin:
	@set -k; ./utility.sh apply_mediawiki_skin mediawikiPath=$(mediawiki_dir) skinSubdirectory=Vector skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git skinBranch=master wfLoadSkin=Vector wgDefaultSkin=vector; \
	make openspecialversionpage;

.PHONY: useapiportalskin
useapiportalskin:
	@set -k; ./utility.sh apply_mediawiki_skin mediawikiPath=$(mediawiki_dir) skinSubdirectory=WikimediaApiPortal skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/WikimediaApiPortal.git skinBranch=master wfLoadSkin=WikimediaApiPortal wgDefaultSkin=WikimediaApiPortal; \
	make openspecialversionpage;

.PHONY: useminervaneueskin
useminervaneueskin:
	@set -k; ./utility.sh apply_mediawiki_skin mediawikiPath=$(mediawiki_dir) skinSubdirectory=MinervaNeue skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue.git skinBranch=master wfLoadSkin=MinervaNeue wgDefaultSkin=minerva; \
	make openspecialversionpage;

.PHONY: usetimelessskin
usetimelessskin:
	@set -k; ./utility.sh apply_mediawiki_skin mediawikiPath=$(mediawiki_dir) skinSubdirectory=Timeless skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Timeless.git skinBranch=master wfLoadSkin=Timeless wgDefaultSkin=timeless; \
	make openspecialversionpage;

special_version_url = "http://localhost:$(mediawiki_port)/wiki/Special:Version"

.PHONY: openspecialversionpage
openspecialversionpage:
	@if [ "$$skipopenspecialversionpage" != "true" ]; then \
		$(makefile_dir)/utility.sh open_url_when_available $(special_version_url); \
	fi

.PHONY: runparsertests
runparsertests:
	@cd $(mediawiki_dir); \
	docker compose exec mediawiki php tests/parser/parserTests.php;

.PHONY: runphpunittests
runphpunittests:
	cd $(mediawiki_dir); \
	docker compose exec --workdir /var/www/html/w/tests/phpunit mediawiki php phpunit.php $(if $(testpath), $(testpath),) $(if $(testgroup), --group $(testgroup),) --testdox;

# applyextensionexample:
# 	set -k; ./utility.sh apply_mediawiki_extension mediawikiPath=$(mediawiki_dir) extensionBranch=master extensionSubdirectory=CampaignEvents extensionRepoURL=https://gerrit.wikimedia.org/r/mediawiki/extensions/CampaignEvents wfLoadExtension=CampaignEvents;
