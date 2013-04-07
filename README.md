# Heyu/X10 state machine and controller written in Coffeescript

A Heyu/X10 state machine that runs on the stand alone command line Mozilla
[Spidermonkey](https://developer.mozilla.org/en-US/docs/SpiderMonkey/Introduction_to_the_JavaScript_shell)
Javascript interpreter, also known as the Javascript shell. This
program runs on
embedded systems that come with [heyu](http://www.heyu.org/).

## Introduction

The X10 protocol can control electrical appliances around the house.
In our house X10 is used to (remotely) control lights, heating, a
water bed and it reboots the ADSL router. For years the heyu tool did
the job, loading the scheduler on a device named a CM11A, the schedule
created by a Ruby script. The nice thing about the CM11A scheduler is
that it runs independently even when computers fail. The not so nice
thing is that the CM11A 'programming language' is archaic and limited.
I wanted more control and move both the scheduler and state machine to
the 'server'.

Also, in earlier times I was running the heyu software on a laptop, which had
to be on to program the CM11A. Recently I moved the CM11A X10 controller to a Netgear
WNDR3700 wifi router, which also has heyu support. I described that
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

Quick examples:

```sh
  heyu-run --id light1 --switch off
  heyu-run --time 2013-04-12 10:45 --id light1 --switch on
  heyu-run --exec
  heyu-run --replay
```

## Advantages of heyu-run

The state-machine and event timer is handled by the heyu-run script
independently. heyu-run only uses the heyu software to send signals to
the CM11A or equivalent controller. In other words, both the heyu
software and the X10 devices are considered dumb switches.  When any
of these gets reset, software or hardware, simply run replay mode to
get to the current state. heyu-run works perfectly with CRON.

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

Note: older versions of Debian may require building node.js.

This will install Coffeescript (with node.js). To test/run our code on
the workstation you will need
[oosp-js](http://www.ossp.org/pkg/lib/js/) there too. I had to build
it from source so it matches the
[OpenWRT](https://dev.openwrt.org/browser/packages/libs/ossp-js/Makefile?rev=24343) one. E.g.

```sh
  /opt/js-1.6.20070208/bin/js --version
  JavaScript-C 1.6 pre-release 1 2006-04-04 (OSSP js 1.6.20070208)
```

and test

```
  ./scripts/helloworld.sh /opt/js-1.6.20070208/bin/js
  Compiling coffeescript...
  Running Mozilla javascript shell...
  hello world
```

Or install the Spidermonkey Javascript interpreter from
[Mozilla](https://developer.mozilla.org/en/docs/SpiderMonkey). You'll
need File writing support with

```sh
make -f Makefile.ref JS_HAS_FILE_OBJECT=1
```

If you get a 'ReferenceError: print is not defined' it means you are
running a non-Spidermonkey Javascript interpreter (probably the one that
comes with node.js).

## Compile and run

First compile the Coffeescript version to Javascript

```sh
  coffee -c bin/heyu-run.coffee lib/*.coffee
```

set the js alias and run a test

```sh
  alias js-1.6=/opt/js-1.6.20070208/bin/js
  js-1.6 bin/heyu-run.js --test
  (...)
  Tests passed
```

To use heyu-run on OpenWRT is similar. Check the scripts in ./script.

## Usage

heyu-run does not actually invoke heyu, but it writes a shell script
to STDOUT, which invokes heyu. This is dictated by the fact that the
spidermonkey edition of Javascript on OpenWRT does not allow for
system calls. But actually this is a good idea: the state machine should
be independent of the switching system. So, to switch on light1 and
update the state machine the command is

```sh
js bin/heyu-run.js --id light1 --switch on | sh
```

and to switch it off

```sh
js bin/heyu-run.js --id light1 --switch off | sh
```

You can see that in both cases heyu gets invoked.  To query the
current state

```sh
js bin/heyu-run.js --id light1 --state 
on
```

to program a timer 

```sh
js bin/heyu-run.js --time yyyy-mm-dd hh:mm --id light1 --switch on | sh
```

which adds the timed command to the event queue.

Run the script and execute programmed state changes

```sh
js bin/heyu-run.js --exec | sh
```

Exec can be run from a cron job - say every few minutes. We make sure
no two jobs can write to the same file at the same time (through
a write lock).

To synchronize all appliances to the state in the local state machine, call
replay

```sh
js bin/heyu-run.js --replay | sh
```

To switch off all known appliances and remove the queue, simply remove
the database files and run --replay. It is safe to run --replay in a
CRON job. I run --replay every few hours.

To catch heyu errors you can send the STDERR output to a file and test the
error return code with bash. We can also use 'tee' to send output to a
log file. E.g.

```bash
set -e
set -o pipefail
js bin/heyu-run.js --exec | tee -a heyu.log | sh 2>> heyu.err
echo $?   # 0 on success, 1 on heyu error
```

A cron job could be to exec every minute and to replay every hour

```cron
* * * * * js heyu-run.js --exec | tee -a heyu.log | sh 2>> heyu.err
0 * * * * js heyu-run.js --replay |sh
```

or more advanced

```cron
* * * * * cd ~/opt/heyu-run && ./scripts/run.sh --exec | tee -a heyu.log | sh 2>> heyu.err
```

on openwrt make sure to enable the cron daemon 

```sh
/etc/init.d/cron enable
/etc/init.d/cron start
```sh

## Bugs / features

It is possible to add multiple events when the state of an appliance
gets changed to the timed events queue, also without using the --time
switch. The time granularity is one minute or second, so it can be the
user adds two or more conflicting events at the same time. Luck will
chose which one is the final state(!). To be on the safe side, remove
the ambiguous event from the database file or add a timed event one
minute or second later.

## Planned for / wished for

* Introduce nicer JS state machine
* Send update messages to a service such as jabber
* Write a schedule for Heyu to upload to the CM11A
* Maybe mix and match with the Heyu state engine

## LICENSE

This software is published under the liberal BSD license. See
LICENSE.TXT. Copyright(c) 2013 Pjotr Prins

