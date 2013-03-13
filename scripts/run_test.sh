#! /bin/sh

js=/opt/js-1.6.20070208/bin/js
coffee -c bin/heyu-run.coffee lib/*.coffee
if [ $? -eq 0 ]; then 
  $js bin/heyu-run.js --test
fi
