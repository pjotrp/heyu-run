@run_tests = () ->
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


