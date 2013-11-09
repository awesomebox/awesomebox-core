q = require = 'q'
exports.type = 'html'
exports.extension = ['md', 'markdown']

exports.process = (opts, data) ->
  marked = require 'marked'
  marked.setOptions(
    gfm: true
    langPrefix: 'language-'
  )
  
  q.nfcall(marked, opts.content.toString())
