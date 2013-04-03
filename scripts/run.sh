#! /bin/bash

# set -e
# set -o pipefail

js=/opt/js-1.6.20070208/bin/js
coffee -c bin/heyu-run.coffee lib/*.coffee
$js bin/heyu-run.js $*
