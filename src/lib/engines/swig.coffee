exports.type = 'html'
exports.extension = 'swig'

exports.process = (opts, data) ->
  swig = require 'swig'
  swig.compile(opts.content.toString(), data)(data)
