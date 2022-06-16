#!/bin/bash

get_response_code () {
   echo $(curl --write-out '%{http_code}' --silent --output /dev/null $1);
}

is_container_running () {
   is_running=$(docker inspect -f '{{.State.Running}}' $1 2>/dev/null);
   [ "$is_running" == "true" ] && echo "true" || echo "false";
}

open_url_when_available () {
   while ! [[ "$(get_response_code $1)" =~ ^(200|301)$ ]]; do sleep 1; done;
   sleep 0.5;
   ( open "$1" || xdg-open "$1" || echo "Unable to automatically open '$1', try opening it in a browser" ) &
}

$*