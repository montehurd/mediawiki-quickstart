<?php

wfLoadExtension( 'CirrusSearch' );
$wgCirrusSearchServers = [ 'elasticsearch' ];
$wgCirrusSearchUseCompletionSuggester = 'yes';
$wgSearchType = 'CirrusSearch';

# Reminder:
# To confirm Cirrus results, use a Cirrus-specific query param, like "cirrusDumpResult=1", when searching for a term, in this case, the string "beef":
#    curl "http://localhost:8080/w/api.php?action=query&list=search&srsearch=beef&srprop=size&format=json&cirrusDumpResult=1"
# To view elastic search indices:
#    curl -X GET "localhost:9200/_cat/indices?v"
# Also useful:
#    curl http://localhost:9200
#    http://localhost:8080/w/api.php
#    http://localhost:8080/w/api.php?action=cirrus-config-dump
#    http://localhost:8080/w/api.php?action=cirrus-check-sanity&from=1
#    http://localhost:8080/w/api.php?action=cirrus-mapping-dump
#    http://localhost:8080/w/api.php?action=cirrus-profiles-dump
#    http://localhost:8080/w/api.php?action=cirrus-settings-dump