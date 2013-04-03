AssertError = (@message) ->

@assert = (expr, message='', got='unknown') ->
  unless expr()
    print 'Assertion failed',message,expr
    print 'Got',got if got isnt 'unknown'
    throw new AssertError(message)

# ---- Clone objects
@clone = (obj) ->
  return obj  if obj is null or typeof (obj) isnt "object"
  temp = obj.constructor()
  for key of obj
    temp[key] = clone(obj[key])
  temp

# ---- File writer 
#
# Writing uses a .LCK file, which gets broken after a second, or so. Just
# to make sure no 2 processes write at exactly the same time.
###
 * {function(string, string)}
###
@write_file = (fn,writer) ->
  lock = new File(fn+".LCK")
  if lock.exists
    print "# Waiting for lock file"
  count = 0
  while lock.exists and count < 1000000
    count += 1
  lock.open("write,create", "text")
  lock.writeln("lock")
  lock.close()
  f = new File(fn)
  try
    f.remove() if f.exists
    f.open("write,create", "text")
    writer(f)
  catch e
    print "File error for",fn
    throw e
  finally
    f.close()
    lock.remove() if lock.exists
