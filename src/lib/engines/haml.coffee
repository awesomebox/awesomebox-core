exports.type = 'html'
exports.extension = 'haml'

exports.process = (opts, data) ->
  haml = require 'hamljs'
  if data.locals?
    locals = data.locals
    data.locals = data
    data.locals.locals = locals
  else
    data.locals = data
  haml.render(opts.content.toString(), data).trimLeft()
