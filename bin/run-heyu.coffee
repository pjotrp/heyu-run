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
  # heyu = exec('ls')
  # Try to write to a file
  file = new File("myfile.txt");
  file.open("write,create", "text")
  file.writeln("The quick brown fox jumped over the lazy dogs")
  file.close()
  file.remove()

  print 'Tests passed'

# ---- Parse the command line
parse_opts = (args) ->
  if args.length > 0
    args2 =
      switch args[0]
        when '--test'
          test()
          args[1..]
        else
          args[1..]
    parse_opts(args2) if args2.length > 0

# ---- Main program
root=this
args=clone(root.arguments)
parse_opts(args)
