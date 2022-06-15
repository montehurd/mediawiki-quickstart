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

.PHONY: applyskin
applyskin:
	@cd $(mediawiki_dir); \
	rm -rf "skins/$(skinDirectory)"; \
	git clone $(if $(skinBranch), --branch $(skinBranch),) $(skinRepoURL) "./skins/$(skinDirectory)" --depth=1; \
	cd $(makefile_dir); \
	sleep 1; \
	make applyskinsettings; \
	make openspecialversionpage;

.PHONY: applyskinsettings
applyskinsettings:
	@cd $(mediawiki_dir); \
	grep -qx '^wfLoadSkin.*$$' LocalSettings.php || echo 'wfLoadSkin("");' >> LocalSettings.php; \
	sed -i -E "s/^wfLoadSkin[[:blank:]]*\(([[:blank:]]*.*[[:blank:]]*)\)[[:blank:]]*;[[:blank:]]*$$/wfLoadSkin(\"$(wfLoadSkin)\");/g" LocalSettings.php; \
	sed -i -E "s/\\\$$wgDefaultSkin.*;[[:blank:]]*$$/\\\$$wgDefaultSkin = \"$(wgDefaultSkin)\";/g" LocalSettings.php;

.PHONY: usevectorskin
usevectorskin:
	make applyskin skinDirectory=Vector skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git wfLoadSkin=Vector wgDefaultSkin=vector;

.PHONY: useapiportalskin
useapiportalskin:
	make applyskin skinDirectory=WikimediaApiPortal skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/WikimediaApiPortal.git wfLoadSkin=WikimediaApiPortal wgDefaultSkin=WikimediaApiPortal;

.PHONY: useminervaneueskin
useminervaneueskin:
	make applyskin skinDirectory=MinervaNeue skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue.git wfLoadSkin=MinervaNeue wgDefaultSkin=minerva;

.PHONY: usetimelessskin
usetimelessskin:
	make applyskin skinDirectory=Timeless skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Timeless.git wfLoadSkin=Timeless wgDefaultSkin=timeless;

special_version_url = "http://localhost:$(mediawiki_port)/wiki/Special:Version"

.PHONY: openspecialversionpage
openspecialversionpage:
	@if [ "$$skipopenspecialversionpage" != "true" ]; then \
		while ! [[ $$($(makefile_dir)/utility.sh get_response_code $(special_version_url)) =~ ^(200|301)$$ ]]; do sleep 1; done; \
		sleep 0.5; \
		( open $(special_version_url) || xdg-open $(special_version_url) || echo "Open '$(special_version_url)' in a browser to view the Mediawiki special version page." ) & \
	fi

.PHONY: runparsertests
runparsertests:
	@cd $(mediawiki_dir); \
	docker compose exec mediawiki php tests/parser/parserTests.php;

.PHONY: runphpunittests
runphpunittests:
	cd $(mediawiki_dir); \
	docker compose exec --workdir /var/www/html/w/tests/phpunit mediawiki php phpunit.php $(if $(testpath), $(testpath),) $(if $(testgroup), --group $(testgroup),) --testdox;

.PHONY: applyextension
applyextension:
	@cd $(mediawiki_dir); \
	rm -rf "extensions/$(extensionDirectory)"; \
	git clone $(if $(extensionBranch), --branch $(extensionBranch),) $(extensionRepoURL) "./extensions/$(extensionDirectory)" --depth=1; \
	cd $(makefile_dir); \
	sleep 1; \
	make applyextensionsettings;

.PHONY: applyextensionsettings
applyextensionsettings:
	@cd $(mediawiki_dir); \
	grep -qx "^[[:blank:]]*wfLoadExtension[[:blank:]]*([[:blank:]]*[\"']$(wfLoadExtension)[\"'][[:blank:]]*)[[:blank:]]*;[[:blank:]]*$$" LocalSettings.php || echo 'wfLoadExtension("$(wfLoadExtension)");' >> LocalSettings.php;
