exports.type = 'html'
exports.extension = 'mustache'

exports.process = (opts, data) ->
  mustache = require 'mustache'
  mustache.to_html(opts.content.toString(), data)
