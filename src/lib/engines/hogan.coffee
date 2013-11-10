exports.type = 'html'
exports.extension = 'hogan'

exports.process = (opts, data) ->
  hogan = require 'hogan.js'
  hogan.compile(opts.content.toString(), data).render(data)
