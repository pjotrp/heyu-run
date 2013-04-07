# Script for HEYU runner with state machine (target spidermonkey javascript interpreter)
#
# See README for more information
#
# by Pjotr Prins (c) 2013

VERSION = '0.1.1'

print "# Heyu-run #{VERSION} by Pjotr Prins"
time=new Date()
print "#",time.toTimeString()
local_date = time.toLocaleFormat("%Y-%m-%d")
local_time = time.toLocaleFormat("%H:%M:%S")

load('lib/util.js')
load('lib/statemachine.js')
load('lib/timedevent.js')

# File names to store state machine and events
state_db_fn = 'heyu-run.db'
event_db_fn = 'heyu-events.db'

# ---- Display help
help = () ->
  print """
  Usage: heyu-run [args]

    --id appl         Appliance id
    --switch ON|OFF   Send event to appliance
    --time            Add timed event (format yyyy-mm-dd hh:mm)
    --state           Show state of appliance
    --exec            Execute any queued timed events
    --replay          Replay state machine and timed events
    --test            Run tests
    --dry-run         Do not save state

  Examples:

    heyu-run --id light1 --switch on
    heyu-run --time 2013-04-12 10:45 --id light1 --switch on
    heyu-run --exec
    heyu-run --replay

  """
  quit(1)

# ---- Parse the command line
parse_opts = (set,args) ->
  if args.length > 0
    args2 =
      switch args[0]
        when '--help','-h' then help()
        when '--test'
          load('test/test.js')
          run_tests()
          set.event = "on"
          set.id  = "test"
          args[1..]
        when '--time'
          set.date = args[1]
          set.time = args[2]
          if not set.time? or set.time[0] == '-' # just time set
            set.time = set.date
            set.date = local_date
          args[3..]
        when '--id'
          set.id = args[1]
          args[2..]
        when '--switch'
          set.event = args[1].toUpperCase()
          args[2..]
        when '--state'
          set.display_state = true
          args[1..]
        when '--exec'
          set.exec = true
          args[1..]
        when '--replay'
          set.replay = true
          args[1..]
        when '--dry-run'
          set.dry_run = true
          args[1..]
        else
          throw "Unknown argument #{args[0]}"
    parse_opts(set,args2) if args2.length > 0
    set

# ---- Main program, parse command line
set = parse_opts({},@arguments)

# ---- Fetch state machine
appliances = read_json(state_db_fn)

# ---- Fetch timed events and update state
events = read_events(event_db_fn)

# ---- Function for updating the appliances state machine
appliances_update = (id,event) ->
  if appliances[id]
    appl1 = appliances[id]
    print "#",id,"is",appl1.currentState()
    appl1.changeState(appl1.currentState(),event)
  else
    print "# new:",event,id
    appl2 = new HeyuAppliance(id, states: ['OFF', 'ON'])
    appl2.changeState(appl2.currentState(),event)
    appliances[appl2.name] = appl2

# ---- Update state machine from command line
if set?.id?
  if set.display_state
    print "# Display current state of",set.id
    print appliances[set.id].currentState()
  if set.event?
    if not set.time
      # Force update of appliance now and record setting in timed events
      appliances_update(set.id,set.event)
      set.date = local_date
      set.time = local_time
      print "# updated",set.id,"at",set.date,set.time
    events.add_ary [set.date+' '+set.time,set.id,set.event]
    write_events(event_db_fn,events) if not set.dry_run

if set.exec? or set.replay?
  print "# Executing timed events"
  state_list = get_last_state(events)
  for appl,e of state_list
    print "# Last event for",appl,"is",e.event,e.time
    appliances_update(e.id,e.event)
  if set.replay?
    print "# Replaying state machine"
    for name,appl of appliances
      appl.heyu_cli(name,appl.currentState())

# ---- Write state machine to file
state_changed = false
for name,appl of appliances
  state_changed = true if appl.changed
write_json(state_db_fn,appliances) if state_changed and not set.dry_run
