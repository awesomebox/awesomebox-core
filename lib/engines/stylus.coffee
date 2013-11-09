exports.type = 'css'
exports.extension = ['styl', 'stylus']
exports.attr_type = ['text/styl', 'text/stylus']

exports.process = (opts) ->
  q = require 'q'
  stylus = require 'stylus'
  q.ninvoke(stylus, 'render', opts.content.toString(), filename: opts.filename)
