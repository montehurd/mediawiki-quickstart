#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
mediawiki_dir="$script_dir/mediawiki"
mediawiki_port=8080

MW_ENV="
MW_DOCKER_PORT=$mediawiki_port
MW_DOCKER_UID=$(id -u)
MW_DOCKER_GID=$(id -g)
MEDIAWIKI_USER=Admin
MEDIAWIKI_PASSWORD=dockerpass
XDEBUG_ENABLE=true
XHPROF_ENABLE=true
XDEBUG_CONFIG=''
"
export MW_ENV

special_version_url="http://localhost:$mediawiki_port/wiki/Special:Version"

fresh_install() {
	stop
	remove
	prepare
	start
}

prepare() {
	mkdir -p "$mediawiki_dir"
	cd "$mediawiki_dir"
	git clone https://gerrit.wikimedia.org/r/mediawiki/core.git . --depth=1
	echo "$MW_ENV" > .env
	cp ./docker-compose.override.yml "$mediawiki_dir/docker-compose.override.yml"
}

remove() {
	if [ -d "$mediawiki_dir" ]; then
		read -p "Are you sure you want to delete mediawiki containers and EVERYTHING in \"$mediawiki_dir\" (y/n)? " -n 1 -r
		echo
		if [ "$REPLY" = "y" ]; then
			cd "$mediawiki_dir"
			docker compose down
			rm -rf "$mediawiki_dir"
			rm "$script_dir/runonce"
		fi
	fi
}

stop() {
	cd "$mediawiki_dir"
	docker compose stop
}

start() {
	if [ ! -f "$script_dir/runonce" ]; then
		cd "$mediawiki_dir"
		docker compose up -d
		docker compose exec mediawiki composer update
		docker compose exec mediawiki bash /docker/install.sh
		sleep 2
		cd "$script_dir"
		touch runonce
		use_vector_skin
    return 0
	fi
	is_running=$("$script_dir/utility.sh" is_container_running "mediawiki-mediawiki-1")
	if [ "$is_running" = false ]; then
		cd "$mediawiki_dir"
		docker compose up -d
		sleep 1
	fi
	cd "$script_dir"
	./utility.sh wait_until_url_available $special_version_url
	open_special_version_page
}

restart() {
	stop
	start
}

bash_mw() {
	cd "$mediawiki_dir"
	docker compose exec mediawiki bash
}

bash_jr() {
	cd "$mediawiki_dir"
	docker compose exec mediawiki-jobrunner bash
}

bash_wb() {
	cd "$mediawiki_dir"
	docker compose exec mediawiki-web bash
}

use_vector_skin() {
	set -k
	"$script_dir/utility.sh" apply_mediawiki_skin mediawikiPath=$mediawiki_dir skinSubdirectory=Vector skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Vector.git skinBranch=master wfLoadSkin=Vector wgDefaultSkin=vector
	open_special_version_page
}

use_apiportal_skin() {
	set -k
	"$script_dir/utility.sh" apply_mediawiki_skin mediawikiPath=$mediawiki_dir skinSubdirectory=WikimediaApiPortal skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/WikimediaApiPortal.git skinBranch=master wfLoadSkin=WikimediaApiPortal wgDefaultSkin=WikimediaApiPortal
	open_special_version_page
}

use_minervaneue_skin() {
	set -k
	"$script_dir/utility.sh" apply_mediawiki_skin mediawikiPath=$mediawiki_dir skinSubdirectory=MinervaNeue skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue.git skinBranch=master wfLoadSkin=MinervaNeue wgDefaultSkin=minerva
	open_special_version_page
}

use_timeless_skin() {
	set -k
	"$script_dir/utility.sh" apply_mediawiki_skin mediawikiPath=$mediawiki_dir skinSubdirectory=Timeless skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/Timeless.git skinBranch=master wfLoadSkin=Timeless wgDefaultSkin=timeless
	open_special_version_page
}

use_monobook_skin() {
	set -k
	"$script_dir/utility.sh" apply_mediawiki_skin mediawikiPath=$mediawiki_dir skinSubdirectory=MonoBook skinRepoURL=https://gerrit.wikimedia.org/r/mediawiki/skins/MonoBook.git skinBranch=master wfLoadSkin=MonoBook wgDefaultSkin=monobook
	open_special_version_page
}

open_special_version_page() {
	if [ "$skipopenspecialversionpage" != "true" ]; then
		"$script_dir/utility.sh" open_url_when_available $special_version_url
	fi
}

run_parser_tests() {
	cd "$mediawiki_dir"
	docker compose exec mediawiki php tests/parser/parserTests.php
}

run_php_unit_tests() {
	cd "$mediawiki_dir"
	docker compose exec --workdir /var/www/html/w/tests/phpunit mediawiki php phpunit.php ${testpath:+$testpath} ${testgroup:+--group $testgroup} --testdox
}

"$@"