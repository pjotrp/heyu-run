# Script for HEYU runner with state machine (target spidermonkey javascript interpreter)
#
# by Pjotr Prins (c) 2013

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
    --test            Run tests

  Examples:

    heyu-run --id light1 --switch on

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
          assert(-> set.time[0] != '-')
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

# ---- Update state machine from command line
if set?.id?
  if set.display_state
    print "# Display current state of",set.id
    print appliances[set.id].currentState()
  if set.time
    events.add_ary [set.date+' '+set.time,set.id,set.event]
    write_events(event_db_fn,events)
  else
    if set.event
      if appliances[set.id]
        appl1 = appliances[set.id]
        print "# in:",set.event,set.id,"was",appl1.currentState()
        appl1.changeState(appl1.currentState(),set.event)
      else
        print "# new:",set.event,set.id
        appl2 = new HeyuAppliance(set.id, states: ['OFF', 'ON'])
        appl2.changeState(appl2.currentState(),set.event)
        appliances[appl2.name] = appl2
if set.exec?
  print "# Executing timed events"
  state_list = get_last_state(events)
  for appl,e of state_list
    print appl,e.event,e.time

# ---- Write state machine to file
state_changed = false
for name,appl of appliances
  state_changed = true if appl.changed
write_json(state_db_fn,appliances) if state_changed
