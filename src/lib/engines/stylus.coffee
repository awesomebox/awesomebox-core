exports.type = 'css'
exports.extension = ['styl', 'stylus']
exports.attr_type = ['text/styl', 'text/stylus']

exports.process = (opts) ->
  q = require 'q'
  path = require 'path'
  stylus = require 'stylus'
  
  full_path = path.join(opts.root, opts.filename)
  
  q.ninvoke(stylus, 'render', opts.content.toString(), filename: opts.filename, dir: [
    path.dirname(full_path)
    opts.root
  ])

exports.enhance_error = (err) ->
  o = err.original_error
  
  msg_parts = o.message.split('\n\n')
  path_parts = msg_parts[0].split('\n')[0].split(':')
  
  err.line = parseInt(o.lineno or path_parts.slice(-1)[0] or -1)
  err.message = msg_parts[1].split('\n')[0]
