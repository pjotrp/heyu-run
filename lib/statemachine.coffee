# Simple state machine, based on coffee-machine by Stephen https://github.com/stephenb

class @StateMachine

  constructor: (@sm = {states:{}, events:{}}) ->
    this.create(@sm)
  
  create: (@sm = {states:{}, events:{}}) ->
    if @sm.states.constructor.toString().indexOf('Array') isnt -1
      # Array initialization
      states = @sm.states
      @sm.states = {}
      for state in states
        @sm.states[state] = { active: (state is states[0]) }
    # Make sure an active state is properly set
    active = (state for own state, state_def of @sm.states when state_def.active)
    if active.length is 0
      # Set the 1st state to active
      for own state, state_def of @sm.states
        state_def.active = true
        break
    else if active.length > 1
      # Set only the 1st active state to active
      for own state in active
        continue if state is active[0]
        state_def.active = false
    # Define the event methods
    for event, eventDef of @sm.events
      do(event, eventDef) =>
        this[event] = -> this.changeState(eventDef.from, eventDef.to, event)
  
  currentState: ->
    (state for own state, state_def of @sm.states when state_def.active)[0]

  availableStates: ->
    state for own state of @sm.states
    
  availableEvents: ->
    event for own event of @sm.events

  # Restore state without invoking events FIXME: ON/OFF only
  restoreState: (state) ->
    if state is 'ON'
      print "# State machine #{@name} is",state
      from = 'OFF'
      to = 'ON'
      states_from = @sm.states[from]
      states_to = @sm.states[to]
      states_from.active = false
      states_to.active = true
    
  changeState: (from, to, event=null) ->
    # If from is an array, and it contains the currentState, set from to currentState
    if from.constructor.toString().indexOf('Array') isnt -1
      if from.indexOf(this.currentState()) isnt -1
        from = this.currentState()
      else
        throw "Cannot change from states #{from.join(' or ')}; none are the active state!"
    # If using 'any', then set the from to whatever the current state is
    if from is 'any' then from = this.currentState()
    
    states_from = @sm.states[from]
    states_to = @sm.states[to]
    
    throw "Cannot change to state '#{to}'; it is undefined!" if states_to is undefined
    throw "Cannot change from state '#{from}'; it is undefined!" if states_from is undefined
    throw "Cannot change from state '#{from}'; it is not the active state!" if states_from.active isnt true
    
    {onEnter: enterMethod, guard: guardMethod} = states_to
    {onExit: exitMethod} = states_from
    
    args = {from: from, to: to, event: event}
    return false if guardMethod isnt undefined and guardMethod.call(this, args) is false
    exitMethod.call(this, args) if exitMethod isnt undefined
    enterMethod.call(this, args) if enterMethod isnt undefined
    @sm.onStateChange.call(this, args) if @sm.onStateChange isnt undefined
    states_from.active = false
    states_to.active = true

  # Persist SM to JSON. Writes something like
  #   {"light1":["ON",["OFF","ON"]]},
  # FIXME: ON/OFF supported only 
  toJSON: ->
    res = '  '+@name+': ["'+@currentState()+'",'
    res += '['
    # for s in @availableStates()
    #   res += '"'+s+'",'
    res += '"OFF","ON"'
    res += ']],'
    res


class @HeyuAppliance extends StateMachine
  constructor: (@name) ->
    @create(
      states:
        OFF:
          onEnter: (args) -> @heyu_exec(args)
          # onExit: -> this.heyu_exec()
        ON:
          onEnter: (args) -> @heyu_exec(args)
      events:
        switchOn: {from:'OFF', to:'ON'}
        switchOff: {from:'ON', to:'OFF'}
    )
    @changed = false
  heyu_cli: (id,event) ->
    print "heyu #{event} #{id}"
  heyu_exec: (args) ->
    if args.from != args.to
      print "# #{@name} switched state",args.from,'to',args.to
      heyu_cli(args.to,@name)
      # print "heyu #{args.to} #{@name}"
      @changed = true
  display_state: () ->
    print "# #{@name} is",@currentState()

# ---- Read JSON file and return a Map of appliance state
#      machines
@read_json = (fn) ->
  file = new File(fn)
  return {} if not file.exists
  load(fn) # Use the JS parser
  # for k,v of state_machines
  #   print '#',k,v
  # state_machines
  appliances = {}
  for name,values of state_machines
    [state,states] = values
    appl = new HeyuAppliance(name, states: states)
    appl.restoreState(state)
    assert((-> appl.currentState() is state),"State",state)
    appliances[name] = appl
  appliances

# ---- Write JSON from list (turns Array into a Map)
@write_json = (fn,appliances) ->
  # Try to write to a file
  print "# Saving state to",fn
  write_file(fn, (f) ->
    f.writeln("state_machines = {")
    for name,appl of appliances
      f.writeln(appl.toJSON())
    f.writeln("}"))


