exports.type = 'js'
exports.extension = 'jsx'
exports.attr_type = ['text/jsx', 'text/react']

remove_comments = (v) ->
  while (idx = v.indexOf('/*')) isnt -1
    v = v.slice(v.indexOf('*/', idx) + 2)
  v

exports.process = (opts, data) ->
  q = require 'q'
  os = require 'os'
  react = require 'react-tools'
  
  content = '/** @jsx React.DOM */' + os.EOL + remove_comments(opts.content.toString())
  q.ninvoke(react, 'transform', content)
