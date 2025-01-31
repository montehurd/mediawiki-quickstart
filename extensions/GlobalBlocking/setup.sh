#!/bin/bash

sed -i '/buster-backports/d' /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/php.list /etc/apt/trusted.gpg.d/php.gpg
apt update
apt install -y sqlite3
sqlite3 cache/sqlite/globalblocking.sqlite < extensions/GlobalBlocking/sql/sqlite/tables-generated-globalblocks.sql
