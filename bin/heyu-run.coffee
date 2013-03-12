# Script for HEYU runner with state machine (target spidermonkey JS)
#
# by Pjotr Prins (c) 2013

load('lib/statemachine.js')
load('lib/timedevent.js')

state_db_fn = 'heyu-run.db'

AssertError = (@message) ->

assert = (expr, message='', got='unknown') ->
  unless expr()
    print 'Assertion failed',message,expr
    print 'Got',got if got isnt 'unknown'
    throw new AssertError(message)

# ---- Clone objects
clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = obj.constructor()
  for key of obj
    temp[key] = clone(obj[key])
  temp

# ---- Read JSON file
read_json = (fn) ->
  file = new File(fn)
  return {} if not file.exists
  load(fn) # Use the JS parser
  # for k,v of state_machines
  #   print '#',k,v
  # state_machines
  appliances = {}
  for name,values of state_machines
    [state,states] = values
    appl = new HeyuAppliance(name, states: states)
    appl.restoreState(state)
    assert((-> appl.currentState() is state),"State",state)
    appliances[name] = appl
  appliances

# ---- Write JSON from list (turns Array into a Map)
write_json = (fn,objs) ->
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
  write_json("myfile.txt",[appl,appl2])
  appls = read_json("myfile.txt")
  keys = []
  for own key,v of appls
    keys.push key
  assert((-> keys.length==2),"read_json",appls.length)
  assert((-> appls["light1"].name is "light1"),"read_json","light1")
  assert((-> appls["light1"].currentState() is "ON"),"read_json","ON")
  assert((-> appls.light2.currentState() is "OFF"),"read_json","OFF")
  print "# persistent state recovered"
  appls.light1.display_state()
  appls.light2.display_state()
  print "# remove persistent file"
  file = new File("myfile.txt")
  file.remove() if file.exists
  print "# Test timer"
  # Create an event that should have happened
  e1 = new TimedEvent
    time:  "2013-01-10 08:00"
    id:    "light1"
    event: "ON"
  e2 = clone(e1)
  assert(-> e1.event is "ON")
  e2.id = 'light2'
  assert(-> e1.id is "light1")
  assert(-> e2.id is "light2")
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
root = this
args = clone(root.arguments)  # don't need to do this, just for fun
set = parse_opts({test: test},args)
appliances = read_json(state_db_fn)
if set.id and set.display_state
  print "# Display current state of",set.id
  print appliances[set.id].currentState()
if set.id and set.event
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
