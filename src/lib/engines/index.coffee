fs = require 'graceful-fs'
path = require 'path'

module.exports = fs.readdirSync(__dirname).reduce (o, filename) ->
  return o if filename.indexOf('index.') is 0 or filename[0] is '.'
  
  e = require path.join(__dirname, filename)
  
  e.type = e.type.toLowerCase()
  e.extension = [e.extension] unless Array.isArray(e.extension)
  e.extension = e.extension.map (i) -> i.toLowerCase()
  if e.attr_type?
    e.attr_type = [e.attr_type] unless Array.isArray(e.attr_type)
    e.attr_type = e.attr_type.map (i) -> i.toLowerCase()
  
  o.engines.push(e)
  
  o.by_type[e.type] ?= {}
  for ext in e.extension
    o.by_type[e.type][ext] = e
    o.by_ext[ext] = e
  
  if e.attr_type?
    o.by_attr_type[a] = e for a in e.attr_type
  
  o
, {engines: [], by_type: {}, by_ext: {}, by_attr_type: {}}
