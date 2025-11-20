#!/bin/bash

apt-get update
apt-get install -y sqlite3
sqlite3 cache/sqlite/globalblocking.sqlite <extensions/GlobalBlocking/sql/sqlite/tables-generated-globalblocks.sql
