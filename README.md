# Heyu/X10 state machine in Coffeescript

A Heyu/X10 state machine that runs on the Mozilla
[Spidermonkey](https://developer.mozilla.org/en-US/docs/SpiderMonkey/Introduction_to_the_JavaScript_shell)
Javascript interpreter, also known as the Javascript shell. Runs on
embedded systems that come with [heyu](http://www.heyu.org/).

Note: this software is under development and does not actually work! I
still need to add the code for
setting timed commands.

## Introduction

The X10 protocol can control electrical appliances around the house.
In our house X10 is used to (remotely) control lights, heating, a
water bed and it reboots the ADSL router. For years the heyu tool did
the job, loading the scheduler on a device named a CM11A, the schedule
created by a Ruby script. The nice thing about the CM11A scheduler is
that it runs independently even when computers fail. The bad thing is
that the CM11A 'programming language' is archaic and limited. I wanted
more control and move the scheduler and state machine to the 'server'.

Also, earlier I was running the heyu software on a laptop, which had
to be on. Recently I moved the CM11A X10 controller to a Netgear
WNDR3700 wifi router, which has heyu installed. I described that
[here](http://thebird.nl/hardware/OpenWRT_On_Netgear_WNDR3700.html).
The Linux OpenWRT distribution has a package for a
[Javascript](http://www.ossp.org/pkg/lib/js/)
interpreter, which is Mozilla Spidermonkey. It means I can run the controller in
Javascript, and write the code in Coffeescript. Nice.

The great thing about Javascript is that it runs almost anywhere!
Javascript is fast (enough) and it has a small memory foot print.  I
am the first to say that programming Javascript is painful when coming
from a Ruby/Python world. Fortunately, Coffeescript generates
Javascript and takes much of that pain away.

## Design

The heyu-run program gets invoked by the user, and also regularly by a
CRON job. In CRON exec mode it reads the timed command queue, and
updates the electrical appliances by writing a shell script, which in
turn invokes heyu. The queue and state machine are maintained in JSON
files on disk. The state machine is simple - appliances are 'on' or
'off'. Later we may add dimming states. Appliances become known to the
state machine when they are used the first time.

Because of the state machine, the correct state will be updated even after a
computer fails and comes back online.

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
source so it matches the OpenWRT one (you could try the spidermonkey
package instead)

```sh
  /opt/js-1.6.20070208/bin/js --version
  JavaScript-C 1.6 pre-release 1 2006-04-04 (OSSP js 1.6.20070208)
  ./scripts/helloworld.sh /opt/js-1.6.20070208/bin/js
  Compiling coffeescript...
  Running Mozilla javascript shell...
  hello world
```

if you get a 'ReferenceError: print is not defined' it means you are
running a different Javascript interpreter (probably node).

## Compile and run

Firts compile the Coffeescript version to Javascript

```sh
  coffee -c bin/heyu-run.coffee
```

set the js and run the test

```sh
  alias js-1.6=/opt/js-1.6.20070208/bin/js
  js-1.6 bin/heyu-run.js --test
  (...)
  Tests passed
```

To use heyu-run on OpenWRT, check the scripts/remote.sh script.

## Usage

heyu-run does not actually invoke heyu, but it writes a shell script
to STDOUT, which invokes heyu. This is dictated by the fact that the
spidermonkey edition of Javascript on OpenWRT does not allow for
system calls. But actually, it is a good idea, the state machine should
be independent of the switching system. So, to switch on light1 and
update the state machine the command is

```sh
js bin/heyu-run.js --id light1 --switch on | sh
```

to query the current state

```sh
js bin/heyu-run.js --id light1 --state 
on
```

to program a timer 

```sh
js bin/heyu-run.js --time 'yyyy-mm-dd hh:mm:ss' --id light1 --switch on | sh
```

which adds the timed command to the command queue.

run the script and execute programmed state changes

```sh
js bin/heyu-run.js --exec | sh
```

Exec mode is the only mode that can change the state machine itself.
This can be run from a cron job - say every few minutes. We make sure
no two jobs can write to the same file at the same time (through
a write lock).

To switch of all known appliances, remove the queue, and reset state run

```sh
js bin/heyu-run.js --reset | sh
```

## LICENSE

This software is published under the liberal BSD license. See
LICENSE.TXT. Copyright(c) 2013 Pjotr Prins

