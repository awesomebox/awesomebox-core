exports.type = 'html'
exports.extension = 'ejs'

exports.process = (opts, data) ->
  ejs = require 'ejs'
  ejs.render(opts.content.toString(), data)
