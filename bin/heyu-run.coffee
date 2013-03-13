# Script for HEYU runner with state machine (target spidermonkey JS)
#
# by Pjotr Prins (c) 2013

load('lib/util.js')
load('lib/statemachine.js')
load('lib/timedevent.js')

state_db_fn = 'heyu-run.db'
event_db_fn = 'heyu-events.db'

# ---- Write JSON from list (turns Array into a Map)
write_json = (fn,appliances) ->
  # Try to write to a file
  file = new File(fn)
  file.remove() if file.exists
  file.open("write,create", "text")
  file.writeln("state_machines = {")
  for name,appl of appliances
    file.writeln(appl.toJSON())
  file.writeln("}")
  file.close()

write_json1 = (fn,objs) ->
  # Try to write to a file
  file = new File(fn)
  file.remove() if file.exists
  file.open("write,create", "text")
  file.writeln("state_machines = {")
  for obj in objs
    file.writeln(obj.toJSON())
  file.writeln("}")
  file.close()

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

# ---- Check sanity of the environment
test = () ->
  print 'Running tests'
  print "# Test state machine"
  sm = new StateMachine(states: ['OFF', 'ON']) # just make sure it compiles
  appl = new HeyuAppliance("light1")
  appl.restoreState("ON")
  print "# Available states",appl.availableStates()
  appl.display_state()
  assert((-> appl.currentState() is "ON"),appl.name,appl.currentState())
  appl.switchOff()
  appl.display_state()
  assert((-> appl.currentState() is "OFF"),appl.name,appl.currentState())
  appl.switchOn()
  appl2 = new HeyuAppliance("light2")
  appl2.display_state()
  appl2.switchOn()
  appl2.display_state()
  appl2.switchOff()
  appl2.display_state()
  appl.display_state()
  print '#',appl.currentState()
  assert((-> appl.currentState() is "ON"),appl.name,appl.currentState())
  assert((-> appl2.currentState() is "OFF"),appl2.name,appl2.currentState())
  print "# write persistent file"
  write_json("test_db.txt",[appl,appl2])
  appls = read_json("test_db.txt")
  # for testing move it into an array
  keys = []
  for own key,v of appls
    keys.push key
  assert((-> keys.length==2),"read_json",keys.length)
  assert((-> appls["light1"].name is "light1"),"read_json","light1")
  assert((-> appls["light1"].currentState() is "ON"),"read_json","ON")
  assert((-> appls.light2.currentState() is "OFF"),"read_json","OFF")
  print "# persistent state recovered"
  appls.light1.display_state()
  appls.light2.display_state()
  print "# remove persistent file"
  file = new File("test_db.txt")
  file.remove() if file.exists
  print "# Test timer"
  # Create an event that should have happened
  events = new TimedEvents
  e1 = new TimedEvent
    time:  "2013-01-10 08:01"
    id:    "light1"
    event: "ON"
  e2 = new TimedEvent
    time:  "2013-01-10 08:00"
    id:    "light2"
    event: "ON"
  assert(-> e1.event is "ON")
  e2.id = 'light2'
  assert(-> e1.id is "light1")
  assert(-> e2.id is "light2")
  events.add(e1)
  events.add(e2)
  events.write('test_events.txt')
  load('test_events.txt')
  events2 = new TimedEvents
  for l1 in timed_events
    print l1[1]
    # parse into events
    events2.add_ary l1
  # sort all timed events
  appl3 = {}
  # walk the list until time is in the future
  sorted_events = [] # timed_events.sort (a,b) -> if a.time > b.time return 1 else return -1
  for e in sorted_events
    # set the state of every device to 'latest'
    print e
    # update the state machine
  print 'Tests passed'
  quit(0)

# ---- Parse the command line
parse_opts = (set,args) ->
  if args.length > 0
    args2 =
      switch args[0]
        when '--help','-h' then help()
        when '--test'
          test()
          set.event = "on"
          set.id  = "test"
          args[1..]
        when '--id'
          set.id = args[1]
          args[2..]
        when '--switch'
          set.event = args[1].toUpperCase()
          args[2..]
        when '--state'
          set.display_state = true
          args[1..]
        else
          throw "Unknown argument #{args[0]}"
    parse_opts(set,args2) if args2.length > 0
    set

# ---- Main program
args = clone(@arguments)  # don't need to do this, just for fun
set = parse_opts({test: test},args)
appliances = read_json(state_db_fn)

if set?.id? and set.id
  if set.display_state
    print "# Display current state of",set.id
    print appliances[set.id].currentState()
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
state_changed = false
for name,appl of appliances
  state_changed = true if appl.changed
if state_changed
  print "# Saving state to",state_db_fn
  list = []
  for name,appl2 of appliances
    # appl2.display_state()
    list.push appl2
  write_json(state_db_fn,list)
