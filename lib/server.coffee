fs = require 'fs'
path = require 'path'
mime = require 'mime'
express = require 'express'
{helpers, Renderer} = require './awesomebox'

app = express()
# renderer = new Renderer(root: path.join(__dirname, '../test/content'))
renderer = new Renderer(root: process.cwd())

app.use express.logger()
app.use (req, res, next) ->
  file = helpers.find_file(renderer.opts.root, req.url)
  return next() unless file?

  renderer.render(file)
  .then (opts) ->
    content_type = mime.lookup(req.url)
    content_type = mime.lookup(opts.type) if content_type is 'application/octet-stream'
    # console.log req.url, opts.type, '->', content_type
    
    res.status(200)
    res.set('Content-Type': content_type)
    res.send(opts.content)
  .catch(next)

app.listen 5050, ->
  require('open')('http://localhost:5050')
