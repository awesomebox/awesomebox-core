exports.type = 'html'
exports.extension = 'underscore'

exports.process = (opts, data) ->
  underscore = require 'underscore'
  underscore.template(opts.content.toString(), null, data)(data).replace(/\n$/, '')
