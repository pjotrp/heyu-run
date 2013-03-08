# Script for HEYU runner
#
# by Pjotr Prins (c) 2013

load('lib/statemachine.js')

# ---- Clone objects
clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = obj.constructor()
  for key of obj
    temp[key] = clone(obj[key])
  temp

# ---- Display help
help = () ->
  print """
  Usage: heyu-run [args]

    --test     Run tests
  """
  throw new Error("Done.");

# ---- Check sanity of the environment
test = () ->
  print 'Running tests'
  # Try to write to a file
  file = new File("myfile.txt");
  file.open("write,create", "text")
  file.writeln("The quick brown fox jumped over the lazy dogs")
  file.close()
  file.remove()
  # Test state machine
  sm = new StateMachine(states: ['OFF', 'ON'])
  print sm.availableStates()
  print sm.currentState()
  appl = new Appl("light1")
  print appl.availableStates()
  appl.display_state()
  appl.switchOn()
  appl.display_state()
  appl.switchOff()
  appl.display_state()
  appl.switchOn()
  appl2 = new Appl("light2")
  print appl2.availableStates()
  appl2.display_state()
  appl2.switchOn()
  appl2.display_state()
  appl2.switchOff()
  appl2.display_state()
  appl.display_state()
  print 'Tests passed'

# ---- Parse the command line
parse_opts = (set,args) ->
  if args.length > 0
    args2 =
      switch args[0]
        when '--help' or '-h'
          help()
        when '--test'
          test()
          set.event = "on"
          set.id  = "test"
          args[1..]
        when '--id'
          set.id = args[1]
          args[2..]
        when '--switch'
          set.event = args[1]
          args[2..]
        else
          throw "Unknown argument #{args[0]}"
    parse_opts(set,args2) if args2.length > 0
    set

# ---- Main program
root = this
args = clone(root.arguments)  # don't need to do this, just for fun
set = parse_opts({test: test},args)
print "heyu",set.event,set.id
