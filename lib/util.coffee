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
@write_file: (fn,do_write) ->
  f = new File(fn)
  f.open("write,create", "text")
  do_write(f)
  # f.remove() if f.exists
  f.close()

