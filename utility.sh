#!/bin/bash

get_response_code () {
   echo $(curl --write-out '%{http_code}' --silent --output /dev/null $1);
}

is_container_running () {
   is_running=$(docker inspect -f '{{.State.Running}}' $1 2>/dev/null);
   [ "$is_running" ] && echo "true" || echo "false";
}

$*