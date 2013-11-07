q = require 'q'
fs = require 'fs'
vm = require 'vm'
path = require 'path'
cheerio = require 'cheerio'
request = require './request'

exports.engines = require './engines'
helpers = exports.helpers = require './helpers'

PARTIAL_INDEX = 12345



box_methods = (opts) ->
  partial = (filename, locals = {}) ->
    filename = path.join(path.dirname(opts.filename), filename).replace(/\/_/g, '/') unless filename[0] is '/'
    
    file = helpers.find_file(opts.root, filename)
    throw new Error('Cannot find parial ' + filename) unless file?
    
    data = {}
    data[k] = v for k, v of opts.data
    data[k] = v for k, v of locals
    
    key = "<!-- [[PARTIAL-#{++PARTIAL_INDEX}]] -->"
    
    opts.promises.push(
      new Renderer(root: opts.root, layouts_disabled: true, indent: (opts.index or 0) + 1).render(file, data)
      .then (res) ->
        opts.content = opts.content.toString().replace(key, res.content.toString())
    )
    
    key
  
  layout = ->
    throw new Error('There is no layout content') unless opts.layout_content?
    opts.layout_content
  
  {
    box:
      content: (filename, locals) ->
        return partial(filename, locals) if filename?
        layout()
  }



parse_filename = (opts) ->
  parsed = helpers.parse_filename(opts.filename)
  opts.engines = parsed.engines
  opts.type = parsed.type
  opts.filename_base = parsed.base

fetch_file = (opts) ->
  q.nfcall(fs.readFile, path.join(opts.root, opts.filename))
  .then (content) ->
    opts.content = content

render = (opts) ->
  data = {}
  data[k] = v for k, v of box_methods(opts)
  data[k] = v for k, v of opts.data
  data[k] = v for k, v of opts.front_matter
  
  opts.engines.reduce (o, ext) ->
    o.then ->
      q.when(exports.engines.by_ext[ext].process(opts, data))
    .then (content) ->
      opts.content = content
  , q()

parse_front_matter = (opts) ->
  content = opts.content.toString('utf8')
  content = content.slice(1) if content.charCodeAt(0) is 0xFEFF
  
  rx_json = /^(\s*\{\{\{([\s\S]+?)\}\}\}\s*)/gi
  # rx_yaml = /^(\s*\{\{\{([\s\S]+?)\}\}\}\s*)/gi
  
  json_match = rx_json.exec(content)
  # yaml_match = rx_yaml.exec(content)
  if json_match?
    json = '{' + json_match[2].replace(/^\s+|\s+$/g, '') + '}'
    opts.content = opts.content.slice(json_match[0].length)
    
    sandbox =
      box:
        data: (url) ->
          if /^https?:\/\//.test(url)
            request(url)
            .catch (err) ->
              throw new Error('box.data could not connect to ' + url) if err.code is 'ENOTFOUND'
              throw err
          else
            file = helpers.find_file(opts.root, url, type: 'data')
            throw new Error('box.data could not find ' + url) unless file?
            
            new Renderer(root: opts.root, indent: (opts.index or 0) + 1).render(file)
            .then (res) ->
              res.content
    
    try
      vm.runInNewContext("this.__foobar__ = #{json};", sandbox)
      opts.front_matter = sandbox.__foobar__
    catch err
      throw new Error('Error parsing front matter of ' + opts.filename + ': ' + err.message)
  # else if yaml_match?
  #   opts.front_matter = 
  else
    opts.front_matter = {}
  
  promises = Object.keys(opts.front_matter)
  .filter((k) -> q.isPromise(opts.front_matter[k]))
  .map (k) ->
    opts.front_matter[k]
    .then (data) ->
      opts.front_matter[k] = data
  
  q.all(promises)

wait_for_promises = (opts) ->
  q.all(opts.promises)

add_cheerio = (opts) ->
  opts.$ = cheerio.load(opts.content.toString())

extract_from_cheerio = (opts) ->
  opts.content = opts.$.html()

render_styles = (opts) ->
  q.all(
    opts.$('style[type]').toArray()
    .map (el) ->
      $el = opts.$(el)
      type = $el.attr('type')
      
      engine = exports.engines.by_attr_type[type]
      return unless engine?
      
      q.when(engine.process($el.html(), {}))
      .then (content) ->
        script = '<style type="text/css"'
        script += ' ' + k + '="' + v + '"' for k, v of el.attribs when k isnt 'type'
        script += '>' + content + '</style>'
        
        $el.replaceWith(script)
  )

render_scripts = (opts) ->
  q.all(
    opts.$('script[type]').toArray()
    .map (el) ->
      $el = opts.$(el)
      type = $el.attr('type')
      
      engine = exports.engines.by_attr_type[type]
      return unless engine?
      
      q.when(engine.process($el.html(), {}))
      .then (content) ->
        script = '<script type="text/javascript"'
        script += ' ' + k + '="' + v + '"' for k, v of el.attribs when k isnt 'type'
        script += '>' + content + '</script>'
        
        $el.replaceWith(script)
  )

find_layout = (opts) ->
  meta = {}
  if opts.front_matter?
    meta[k] = v for k, v of opts.front_matter
  meta[k] = v for k, v of opts.data
  
  file = helpers.find_layout_file(opts.root, opts.filename, meta)
  opts.layout = file if file? and file isnt opts.filename

render_layout = (opts) ->
  return unless opts.layout?
  
  new Renderer(root: opts.root, layout_content: opts.content.toString(), indent: (opts.index or 0) + 1).render(opts.layout, opts.data)
  .then (res) ->
    opts.content = res.content.toString()

class Renderer
  constructor: (@opts) ->
    throw new Error('Must pass root to Renderer') unless @opts.root?
  
  render: (filename, data = {}) ->
    opts = {}
    opts[k] = v for k, v of @opts
    opts.filename = filename
    opts.data = data
    opts.promises ?= []
    
    console.log Array((opts.indent or 0) * 2 + 1).join('-') + 'START', opts.filename
    
    q()
    .then(-> fetch_file(opts))
    .then(-> parse_filename(opts))
    
    .then ->
      return unless opts.type is 'html'
      
      q()
      .then(-> parse_front_matter(opts))
    
    .then(-> render(opts))
    
    .then ->
      return unless opts.type is 'html'
      
      q()
      .then(-> wait_for_promises(opts))
      .then(-> add_cheerio(opts))
      .then(-> render_styles(opts))
      .then(-> render_scripts(opts))
      .then(-> extract_from_cheerio(opts))
      
      .then ->
        return if opts.layouts_disabled
        
        q()
        .then(-> find_layout(opts))
        .then(-> render_layout(opts))
    
    .then ->
      console.log Array((opts.indent or 0) * 2 + 1).join('-') + 'DONE ', opts.filename
    .then -> opts

exports.Renderer = Renderer
