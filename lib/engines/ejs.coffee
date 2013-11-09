exports.type = 'html'
exports.extension = 'ejs'

exports.process = (opts, data) ->
  ejs = require 'ejs'
  ejs.compile(opts.content.toString(), data)(data)
