exports.type = 'js'
exports.extension = 'coffee'
exports.attr_type = [
  'text/coffeescript'
  'text/coffee-script'
]

exports.process = (opts, data) ->
  coffee = require 'coffee-script'
  coffee_opts = {bare: true}
  # coffee_opts[k] = v for k, v of opts
  coffee.compile(opts.content.toString(), coffee_opts)

exports.enhance_error = (err) ->
  o = err.original_error
  
  console.log o
  console.log o.location
  
  err.line = parseInt(if o.location.first_line then o.location.first_line + 1 else -1)
  err.message = o.message
