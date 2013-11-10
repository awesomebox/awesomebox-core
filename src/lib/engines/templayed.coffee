exports.type = 'html'
exports.extension = 'templayed'

exports.process = (opts, data) ->
  templayed = require 'templayed'
  templayed(opts.content.toString())(data)
