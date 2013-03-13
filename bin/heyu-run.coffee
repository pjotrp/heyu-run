# Script for HEYU runner with state machine (target spidermonkey JS)
#
# by Pjotr Prins (c) 2013

load('lib/util.js')
load('lib/statemachine.js')
load('lib/timedevent.js')

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
set = parse_opts({},args)
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
