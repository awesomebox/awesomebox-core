exports.type = 'css'
exports.extension = 'less'
exports.attr_type = 'text/less'

exports.process = (opts) ->
  q = require 'q'
  path = require 'path'
  less = require 'less'
  
  full_path = path.join(opts.root, opts.filename)
  parser = new less.Parser(
    paths: [
      path.dirname(full_path)
      opts.root
    ]
    filename: full_path
  )
  
  q.ninvoke(parser, 'parse', opts.content.toString())
  .then (tree) ->
    tree.toCSS()

exports.enhance_error = (err) ->
  o = err.original_error
  
  err.line = parseInt(o.line or -1)
  err.message = o.message
