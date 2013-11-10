exports.type = 'html'
exports.extension = 'ejs'

exports.process = (opts, data) ->
  ejs = require 'ejs'
  ejs.compile(opts.content.toString(), data)(data)

exports.enhance_error = (err) ->
  o = err.original_error
  
  msg_parts = o.message.split('\n')
  path_parts = msg_parts[0].split(':')
  
  err.line = parseInt(o.lineno or path_parts.slice(-1)[0] or -1)
  err.message = msg_parts.slice(-1)[0]
