# Script for HEYU runnen
#
# by Pjotr Prins (c) 2013

# ---- Clone objects
clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = obj.constructor()
  for key of obj
    temp[key] = clone(obj[key])
  temp

# ---- Check sanity of the environment
test = () ->
  print 'Running tests'
  # Try to write to a file
  file = new File("myfile.txt");
  file.open("write,create", "text")
  file.writeln("The quick brown fox jumped over the lazy dogs")
  file.close()
  file.remove()

  print 'Tests passed'

# ---- Parse the command line
parse_opts = (set,args) ->
  if args.length > 0
    args2 =
      switch args[0]
        when '--test'
          test()
          args[1..]
        when '--id'
          set.id = args[1]
          args[2..]
        when '--act'
          set.act = args[1]
          args[2..]
        else
          throw "Unknown argument #{args[0]}"
    parse_opts(set,args2) if args2.length > 0
    set

# ---- Main program
root = this
args = clone(root.arguments)
set = parse_opts({test: test},args)
print "heyu",set.act,set.id
