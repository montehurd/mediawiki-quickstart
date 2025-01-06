#!/bin/bash

cd extensions/WikiLambda
git submodule update --init --recursive --remote
cd ~

php maintenance/run.php createAndPromote --custom-groups functioneer,functionmaintainer --force Admin