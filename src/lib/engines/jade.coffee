exports.type = 'html'
exports.extension = 'jade'

exports.process = (opts, data) ->
  jade = require 'jade'
  jade.render(opts.content.toString(), data)
