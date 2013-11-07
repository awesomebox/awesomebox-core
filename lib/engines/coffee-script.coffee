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
