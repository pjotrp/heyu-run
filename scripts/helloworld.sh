#! /bin/sh

js=$1
if [ -z $js ] ; then js=js ; fi

echo "Compiling coffeescript..."
coffee -c ./bin/helloworld.coffee
echo "Running Mozilla javascript shell..."
$js ./bin/helloworld.js
