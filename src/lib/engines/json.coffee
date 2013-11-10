exports.type = 'data'
exports.extension = 'json'

exports.process = (opts) ->
  vm = require 'vm'
  sandbox = {}
  
  try
    vm.runInNewContext("this.__foobar__ = #{opts.content.toString()};", sandbox)
    sandbox.__foobar__
  catch err
    throw new Error('Error parsing front matter of ' + opts.filename + ': ' + err.message)
