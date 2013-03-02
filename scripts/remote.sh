#! /bin/sh

echo "Compile and test..."
js=/opt/js-1.6.20070208/bin/js
coffee -c bin/run-heyu.coffee 
$js bin/run-heyu.js --test 
echo "Pushing script across..."
scp bin/run-heyu.js root@192.168.1.1:
echo "Test remote... "
ssh root@192.168.1.1 "js run-heyu.js --test"
echo "Run remote... " $*
ssh root@192.168.1.1 "js run-heyu.js $* | sh"
