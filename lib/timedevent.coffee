# Timed events

root = this

root.TimedEvent = class TimedEvent
  constructor: (args = {}) ->
    @time = args.time
    @id = args.id
    @event = args.event

