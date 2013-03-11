# Script for HEYU runner with state machine (target spidermonkey JS)
#
# by Pjotr Prins (c) 2013

load('lib/statemachine.js')

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
  load(fn) # Use the JS parser
  # print "JSON",json[0]["light1"]
  for obj in state_machines
    for k,v of obj
      print '#',k,v
  # state_machines
  list = []
  for obj in state_machines
    for name,values of obj
      [state,states] = values
      appl = new HeyuAppliance(name, states: states)
      appl.changeState('any',state)
    list.push appl
  list

# ---- Write JSON
write_json = (fn,objs) ->
  # Try to write to a file
  file = new File(fn)
  file.remove() if file.exists
  file.open("write,create", "text")
  file.writeln("state_machines = [")
  for obj in objs
    file.writeln(obj.toJSON())
  file.writeln("]")
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
  # Test state machine
  sm = new StateMachine(states: ['OFF', 'ON']) # just make sure it compiles
  appl = new HeyuAppliance("light1")
  print "# Available states",appl.availableStates()
  appl.display_state()
  appl.switchOn()
  appl.display_state()
  appl.switchOff()
  appl.display_state()
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
  list = read_json("myfile.txt")
  assert((-> list.length==2),"read_json",list.length)
  assert((-> list[0].name is "light1"),"read_json",list[0].name)
  assert((-> list[1].name is "light2"),"read_json",list[0].name)
  assert((-> list[0].currentState() is "ON"),"read_json",list[0].currentState())
  assert((-> list[1].currentState() is "OFF"),"read_json",list[0].currentState())
  print "# persistent state recovered"
  list[0].display_state()
  list[1].display_state()
  print "# remove persistent file"
  file = new File("myfile.txt")
  file.remove() if file.exists
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
        else
          throw "Unknown argument #{args[0]}"
    parse_opts(set,args2) if args2.length > 0
    set

# ---- Main program
root = this
args = clone(root.arguments)  # don't need to do this, just for fun
set = parse_opts({test: test},args)
appliances = read_json(state_db_fn)
print "# in:",set.event,set.id
appl = new HeyuAppliance(set.id, states: ['OFF', 'ON'])
appl.changeState('any',set.event)
appliances.push appl
print "# Saving state to",state_db_fn
write_json(state_db_fn,appliances)
