#!/bin/bash

# cypress-multi-reporters is a peer dep of cypress-parallel but isn't in
# WikibaseLexeme's package.json. Workspace hoisting puts it at the root
# node_modules/ but Cypress only looks in the extension's own node_modules/.
# Install it directly into the extension to fix reporter resolution.
#
# TODO: WikibaseLexeme should add cypress-multi-reporters as a devDependency
# in its package.json, which would make this workaround unnecessary.

cd extensions/WikibaseLexeme
npm install --no-workspaces --no-save cypress-multi-reporters 2>&1
