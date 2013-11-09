q = require 'q'

class Steps
  constructor: (steps) ->
    @root = {'/': steps}
  
  execute: (opts, current) ->
    return @execute(opts, @root['/']) unless current?
    
    o = q()
  
    Object.keys(current).forEach (k) =>
      v = current[k]
      o = o.then =>
        return v(opts) if typeof v is 'function'
      
        [filter, arg] = k.split(':')
        throw new Error("Invalid filter #{filter}") unless Steps.filters[filter]?
        return unless Steps.filters[filter](opts, arg)
      
        @execute(opts, v)
  
    o
  
  find_level_with_step: (name, current, parent, parent_key) ->
    return @find_level_with_step(name, @root['/'], @root) unless current?
    
    for k, v of current
      unless typeof v is 'function'
        a = @find_level_with_step(name, v, current, k)
        return a if a?
      else
        return [current, parent, parent_key] if k is name
    null
  
  insert: (step, where) ->
    new_k = Object.keys(step)[0]
    new_f = step[new_k]
    
    if where.before? or where.after?
      [level, parent, parent_key] = @find_level_with_step(where.before)
      new_level = {}
      for k, v of level
        if where.before?
          new_level[new_k] = new_f if k is where.before
        new_level[k] = level[k]
        if where.after?
          new_level[new_k] = new_f if k is where.after
      parent[parent_key] = new_level

module.exports = Steps
