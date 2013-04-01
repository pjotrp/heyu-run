# Timed events
#
# Timed events are events with a time stamp attached. These are stored in a DB file 
# with the JSON format:
#
#   timed_events = [
#   ["2013-10-10 10:00","light1","ON"],
#   ["2013-10-13 10:00","light1","OFF"],
#   ]
# 
# In --exec mode the event file gets read from disk and the last command before
# the current time is sent to the state machine.

class @TimedEvent
  constructor: (args = {}) ->
    @time = args.time
    @id = args.id
    @event = args.event
    @changed = false

class @TimedEvents
  constructor: ->
    @list = []
  add: (e) ->
    # print "# Adding time",e.time
    @list.push [event2date(e),e]
    @changed = true
  add_ary: (l) ->
    e = new TimedEvent
    e.time = l[0]
    e.id = l[1]
    e.event = l[2]
    @add(e)
  sorted_list: () ->
    res = @list.sort (e1,e2) ->
      if e1[0] == e2[0]
        0
      else
        if e1[0] > e2[0]
          1
        else
          -1
    res

@write_events = (fn, events) ->
    return if not events.changed
    print "# Writing changed",fn
    list = events.list
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

@get_last_state = (events) ->
  last = {}
  sorted_list = events.sorted_list()
  current_time = Date.now()
  for event in sorted_list
    [stamp,e] = event
    if stamp.getTime() < current_time
      # print stamp,stamp.getTime(),current_time
      last[e.id] = e
  last

# --- Local helper methods

event2date = (e) ->
  # unpack 2013-01-10 08:00
  try
    [x,y,m,d,h,min] = e.time.match(/(\d\d\d\d)-([0123]?\d)-(\d{1,2}) ([012]?\d):(\d\d)/)
    assert(-> 2013 <= y < 2100)
    assert(-> 0 <= m <= 11)
    assert(-> 1 <= d <= 31)
    assert(-> 0 <= h <= 23)
    assert(-> 0 <= min <= 59)
  catch error
    print "Bad time description: ",e.time
    throw error
  new Date(y,m-1,d,h,min)

