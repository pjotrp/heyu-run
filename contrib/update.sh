#! /bin/bash

echo "Use -r switch to reset module"

if [ "$1" == '-r' ]; then
  echo "Resetting"
  rmmod pl2303
  sleep 1
  modprobe pl2303
  sleep 1
  heyu off tv
fi

./heyu.rb heyu.in > x10.sched
scp x10.sched root@192.168.1.1:
ssh root@192.168.1.1 "heyu -s x10.sched upload"

