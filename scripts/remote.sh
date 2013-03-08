#! /bin/sh

echo "Compile and test..."
js=/opt/js-1.6.20070208/bin/js
coffee -c bin/heyu-run.coffee 
$js bin/heyu-run.js --test 
echo "Pushing script across..."
scp bin/heyu-run.js root@192.168.1.1:
echo "Test remote... "
ssh root@192.168.1.1 "js heyu-run.js --test"
echo "Run remote... " $*
ssh root@192.168.1.1 "js heyu-run.js $* | sh"
