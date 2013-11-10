exports.type = 'html'
exports.extension = 'nunjucks'

exports.process = (opts, data) ->
  q = require 'q'
  nunjucks = require 'nunjucks'
  
  q.ninvoke(nunjucks, 'renderString', opts.content.toString(), data)
