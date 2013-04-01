# Timed events

class @TimedEvent
  constructor: (args = {}) ->
    @time = args.time
    @id = args.id
    @event = args.event
    @changed = false

class @TimedEvents
  constructor: ->
    @list = []
  event2date: (e) ->
    # unpack 2013-01-10 08:00
    try
      [x,y,m,d,h,m] = e.time.match(/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d)/)
    catch error
      print "Bad time description: ",e.time
      throw error
    new Date(y,m,d,h,m)
  add: (e) ->
    # print "# Adding time",e.time
    @list.push [@event2date(e),e]
    @changed = true
  add_ary: (l) ->
    e = new TimedEvent
    e.time = l[0]
    e.id = l[1]
    e.event = l[2]
    @add(e)
  write: (fn) ->
    return if not @changed
    print "# Writing changed",fn
    list = @list
    write_file(fn, (f) ->
      f.writeln("timed_events = [")
      for rec in list
        [date,e] = rec
        # f.writeln(date.valueOf())
        f.writeln('["',e.time,'","',e.id,'","',e.event,'"],')
      f.writeln("]")
    )

@read_events = (fn) ->
  events = new TimedEvents
  f = new File(fn)
  return events if not f.exists
  f.close
  load(fn) # Use the JS parser
  for event in timed_events
    events.add_ary(event)
  events.changed = false
  events

