#! /bin/sh

if [ -z $js ] ; then
  js=/opt/js-1.6.20070208/bin/js
fi
coffee -c bin/heyu-run.coffee lib/*.coffee test/*.coffee
if [ $? -eq 0 ]; then 
  $js bin/heyu-run.js --test
fi
