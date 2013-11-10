exports.type = 'css'
exports.extension = ['sass', 'scss']
exports.attr_type = ['text/sass', 'text/scss']

exports.process = (opts) ->
  q = require 'q'
  sass = require 'sass'
  
  q.ninvoke(sass, 'render', opts.content.toString())
