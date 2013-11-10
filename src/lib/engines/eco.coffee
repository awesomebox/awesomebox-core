exports.type = 'html'
exports.extension = 'eco'

exports.process = (opts, data) ->
  eco = require 'eco'
  eco.render(opts.content.toString(), data)
