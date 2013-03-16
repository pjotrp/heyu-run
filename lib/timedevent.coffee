# Timed events

class @TimedEvent
  constructor: (args = {}) ->
    @time = args.time
    @id = args.id
    @event = args.event

class @TimedEvents
  constructor: ->
    @list = []
  event2date: (e) ->
    # unpack 2013-01-10 08:00
    [x,y,m,d,h,m] = e.time.match(/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d)/)
    new Date(y,m,d,h,m)
  add: (e) ->
    print e.time
    @list.push [@event2date(e),e]
  add_ary: (l) ->
    e = new TimedEvent
    e.time = l[0]
    e.id = l[1]
    e.event = l[2]
    @add(e)
  write: (fn) ->
    list = @list
    @write_file(fn, (f) ->
      f.writeln("timed_events = [")
      for rec in list
        [date,e] = rec
        # f.writeln(date.valueOf())
        f.writeln('["',e.time,'","',e.id,'","',e.event,'"],')
      f.writeln("]")
    )

