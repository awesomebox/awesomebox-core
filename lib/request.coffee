q = require 'q'
url = require 'url'
http = require 'http'
https = require 'https'

module.exports = (target) ->
  d = q.defer()
  
  opts = url.parse(target)
  opts.method = 'GET'
  opts.agent = false
  
  req = (if opts.protocol is 'https:' then https else http).request opts, (res) ->
    status = parseInt(res.statusCode / 100)
    if status is 3 and res.headers.location?
      return d.resolve(module.exports(res.headers.location))
    
    chunks = []
    res.on 'error', (err) -> d.reject(err)
    res.on 'data', (chunk) -> chunks.push(chunk)
    res.on 'end', (chunk) ->
      chunks.push(chunk) if chunk?
      
      try
        data = Buffer.concat(chunks).toString()
        d.resolve(JSON.parse(data)) if status is 2
        
        err = new Error(res.statusCode + ': ' + http.STATUS_CODES[res.statusCode])
        err.statusCode = res.statusCode
        err.body = data
        d.reject(err)
      catch err
        d.reject(err)
  
  req.on 'error', (err) -> d.reject(err)
  req.end()
  
  d.promise
