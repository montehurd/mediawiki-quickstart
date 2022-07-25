#!/bin/bash

get_response_code () {
   echo $(curl --write-out '%{http_code}' --silent --output /dev/null $1);
}

is_container_running () {
   is_running=$(docker inspect -f '{{.State.Running}}' $1 2>/dev/null);
   [ "$is_running" == "true" ] && echo "true" || echo "false";
}

open_url_when_available () {
   # TODO: find linux command which can accept name of browser optionally specified in $2 ( it's working for "open" on MacOS below )
   wait_until_url_available "$1";
   ( open ${2:+-a "$2"} "$1" || xdg-open "$1" || echo "Unable to automatically open '$1', try opening it in a browser" )
}

wait_until_url_available () {
   while ! [[ "$(get_response_code $1)" =~ ^(200|301)$ ]]; do sleep 1; done;
   sleep 0.5;
}

# args
# $1 - mediawiki path
# $2 - wfLoadSkin value
# $3 - wgDefaultSkin value
apply_mediawiki_skin_settings () {
	cd $1;
	grep -qx '^wfLoadSkin.*$' LocalSettings.php || echo 'wfLoadSkin("");' >> LocalSettings.php;
	sed -i -E "s/^wfLoadSkin[[:blank:]]*\(([[:blank:]]*.*[[:blank:]]*)\)[[:blank:]]*;[[:blank:]]*$/wfLoadSkin(\"$2\");/g" LocalSettings.php;
	sed -i -E "s/\\\$wgDefaultSkin.*;[[:blank:]]*$/\\\$wgDefaultSkin = \"$3\";/g" LocalSettings.php;
}

"$@"