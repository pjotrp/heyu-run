# Heyu/X10 state engine in Coffeescript

## Introduction

The X10 protocol can control electrical appliances around the house.
In our house X10 is used to (remotely) control lights, heating, a
water bed and it reboots the ADSL router. For years the heyu tool did
the job, loading the scheduler on a device named a CM11A. The nice
thing about the CM11A controller is that it runs independently even
when computers fail. The bad thing is that the CM11A 'programming
language' is archaic and limited. I want more control.

Also, earlier I was running the heyu software on a laptop, which had
to be on. Recently I moved the CM11A X10 controller to a Netgear
WNDR3700 wifi router, which has heyu. I described that
[http://thebird.nl/hardware/OpenWRT_On_Netgear_WNDR3700.html here].
OpenWRT has a package for a [http://www.ossp.org/pkg/lib/js/
Javascript] interpreter, which means I can run the controller in
Javascript, and write it in Coffeescript. Nice.

The great thing about Javascript is that it runs almost anywhere!
Javascript is fast (enough) and it has a small memory foot print.  I
am the first to say that programming Javascript is painful when coming
from a Ruby/Python world. Coffeescript generates Javascript, and takes
much of that pain away.

## Setting up the environment

Coffeescript needs to be installed on a workstation (it is not on
OpenWRT just yet). On Debian

```sh
  apt-get install coffeescript
  coffee --version
  CoffeeScript version 1.1.2
  js --version
  v0.4.12
```

This will install Coffeescript with node.js. To test code on the
workstation you will need oosp-js there too. I had to build it from
source so it matches the OpenWRT one

```sh
  /opt/js-1.6.20070208/bin/js --version
  JavaScript-C 1.6 pre-release 1 2006-04-04 (OSSP js 1.6.20070208)
  ./scripts/helloworld.sh /opt/js-1.6.20070208/bin/js
  Compiling coffeescript...
  Running Mozilla javascript shell...
  hello world
```

if you get a 'ReferenceError: print is not defined' it means you are
running a different Javascript interpreter.

## Compile and run

Firts compile the Coffeescript version to Javascript

```sh
  coffee -c bin/run-heyu.coffee
```

set the js and run the test

```sh
  alias js-1.6=/opt/js-1.6.20070208/bin/js
  js-1.6 bin/run-heyu.js --test
```

# LICENSE

This software is published under the liberal BSD license. See
LICENSE.TXT. Copyright(c) 2013 Pjotr Prins

