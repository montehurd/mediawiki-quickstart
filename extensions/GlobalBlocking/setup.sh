#!/bin/bash

apt update
apt install -y sqlite3
sqlite3 cache/sqlite/globalblocking.sqlite < extensions/GlobalBlocking/sql/sqlite/tables-generated-globalblocks.sql
