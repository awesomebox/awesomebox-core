exports.type = 'data'
exports.extension = ['yml', 'yaml']

exports.process = (opts) ->
  yaml = require 'js-yaml'
  yaml.load(opts.content.toString())
