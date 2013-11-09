exports.type = 'html'
exports.extension = 'liquor'

exports.process = (opts, data) ->
  liquor = require 'liquor'
  liquor.compile(opts.content.toString(), data)(data)
