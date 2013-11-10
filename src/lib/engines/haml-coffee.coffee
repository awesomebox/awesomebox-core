exports.type = 'html'
exports.extension = 'haml-coffee'

exports.process = (opts, data) ->
  haml = require 'haml-coffee'
  haml.compile(opts.content.toString(), data)(data)
