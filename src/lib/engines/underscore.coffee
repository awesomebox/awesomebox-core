exports.type = 'html'
exports.extension = 'underscore'

exports.process = (opts, data) ->
  os = require 'os'
  underscore = require 'underscore'
  rx = new RegExp(os.EOL + '$')
  underscore.template(opts.content.toString(), null, data)(data).replace(rx, '')
