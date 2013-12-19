q = require 'q'
fs = require 'graceful-fs'
vm = require 'vm'
os = require 'os'
path = require 'path'
yaml = require 'js-yaml'
cheerio = require 'cheerio'
request = require './request'

exports.errors = require './errors'
exports.engines = require './engines'
helpers = exports.helpers = require './helpers'
Steps = require './steps'

PARTIAL_INDEX = 12345



box_methods = (opts) ->
  partial = (filename, locals = {}) ->
    throw new Error('A filename must be specified to render partials') unless filename?
    
    filename = path.join(path.dirname(opts.filename), filename).replace(/\/_/g, '/') unless filename[0] is '/'
    
    file = helpers.find_file(opts.root, filename)
    throw new Error('Cannot find parial ' + filename) unless file?
    
    data = {}
    data[k] = v for k, v of opts.data
    data[k] = v for k, v of locals
    
    key = "<!-- [[PARTIAL-#{++PARTIAL_INDEX}]] -->"
    
    opts.promises.push(
      new Renderer(root: opts.root, parent: opts.renderer, layouts_disabled: true).render(file, data)
      .then (res) ->
        opts.content = opts.content.toString().replace(key, res.content.toString())
    )
    
    key
  
  layout = ->
    throw new Error('There is no layout content') unless opts.layout_content?
    opts.layout_content
  
  {
    yield: layout
    render: partial
  }


strip_bom = (opts) ->
  opts.content = opts.content.toString('utf8')
  opts.content = opts.content.slice(1) if opts.content.charCodeAt(0) is 0xFEFF

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
  
  opts.engines.reverse().reduce (o, ext) ->
    engine = exports.engines.by_ext[ext]
    o.then ->
      engine.process(opts, data)
    .then (content) ->
      opts.content = content
    .catch (err) ->
      err = exports.errors.engine(err, engine, opts, data)
      engine.enhance_error?(err)
      throw err
  , q()

parse_front_matter = (opts) ->
  rx_json = new RegExp('^(\\s*\\{\\{\\{([\\s\\S]+?)\\}\\}\\}\\s*)' + os.EOL, 'gi')
  rx_yaml = new RegExp('^(\\s*---([\\s\\S]+?)---\\s*)' + os.EOL, 'gi')
  
  json_match = rx_json.exec(opts.content.toString())
  yaml_match = rx_yaml.exec(opts.content.toString())
  
  if json_match?
    json = '{' + json_match[2].replace(/^\s+|\s+$/g, '') + '}'
    opts.content = opts.content.slice(json_match[0].length)
    
    sandbox =
      data: (url) ->
        if /^https?:\/\//.test(url)
          request(url)
          .catch (err) ->
            throw new Error('box.data could not connect to ' + url) if err.code is 'ENOTFOUND'
            throw err
        else
          file = helpers.find_file(opts.root, url, type: 'data')
          throw new Error('box.data could not find ' + url) unless file?
          
          new Renderer(root: opts.root, parent: opts.renderer).render(file)
          .then (res) ->
            res.content
    
    try
      vm.runInNewContext("this.__foobar__ = #{json};", sandbox)
      opts.front_matter = sandbox.__foobar__
    catch err
      throw new Error('Error parsing front matter of ' + opts.filename + ': ' + err.message)
  else if yaml_match?
    opts.content = opts.content.slice(yaml_match[0].length)
    opts.front_matter = yaml.load(yaml_match[2].replace(/^\s+|\s+$/g, '')) or {}
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
      
      style_opts = {}
      style_opts[k] = v for k, v of opts
      style_opts.content = $el.html()
      
      q()
      .then(-> engine.process(style_opts, {}))
      .then (content) ->
        script = '<style type="text/css"'
        script += ' ' + k + '="' + v + '"' for k, v of el.attribs when k isnt 'type'
        script += '>' + content + '</style>'
        
        $el.replaceWith(script)
      .catch (err) ->
        err = exports.errors.engine(err, engine, style_opts, {})
        engine.enhance_error?(err)
        throw err
  )

render_scripts = (opts) ->
  q.all(
    opts.$('script[type]').toArray()
    .map (el) ->
      $el = opts.$(el)
      type = $el.attr('type')
      
      engine = exports.engines.by_attr_type[type]
      return unless engine?
      
      script_opts = {}
      script_opts[k] = v for k, v of opts
      script_opts.content = $el.html()
      
      q()
      .then(-> engine.process(script_opts, {}))
      .then (content) ->
        script = '<script type="text/javascript"'
        script += ' ' + k + '="' + v + '"' for k, v of el.attribs when k isnt 'type'
        script += '>' + content + '</script>'
      
        $el.replaceWith(script)
      .catch (err) ->
        err = exports.errors.engine(err, engine, script_opts, {})
        engine.enhance_error?(err)
        throw err
  )

find_layout = (opts) ->
  meta = {}
  if opts.front_matter?
    meta[k] = v for k, v of opts.front_matter
  # meta[k] = v for k, v of opts.data
  
  file = helpers.find_layout_file(opts.root, opts.filename, meta)
  opts.layout = file if file? and file isnt opts.filename

render_layout = (opts) ->
  return unless opts.layout?
  
  layout_name = path.basename(opts.layout).split('.')[0]
  return if opts.parent? and layout_name is 'default' and not opts.front_matter.layout?
  
  new Renderer(root: opts.root, parent: opts.renderer, layout_content: opts.content.toString()).render(opts.layout, opts.data)
  .then (res) ->
    opts.content = res.content.toString()


Steps.filters =
  type: (opts, type) -> opts.type is type
  'layouts-enabled': (opts, bool) ->
    return true if opts.layouts_disabled is true and bool.toLowerCase() is 'false'
    return true if !(opts.layouts_disabled is true) and bool.toLowerCase() is 'true'
    false
  'has-parent': (opts, bool) ->
    return true if opts.parent? and bool.toLowerCase() is 'true'
    return true if !opts.parent? and bool.toLowerCase() is 'false'
    false

class Renderer
  constructor: (@opts) ->
    throw new Error('Must pass root to Renderer') unless @opts.root?
    
    @opts.renderer = @
    
    if @opts.parent?.steps?
      @steps = @opts.parent.steps
    
    @steps ?=
      'pre-process': new Steps(
        'fetch-file': fetch_file
        'strip-bom': strip_bom
        'parse-filename': parse_filename
        'type:html':
          'parse-front-matter': parse_front_matter
          'layouts-enabled:true':
            'find-layout': find_layout
      )
      render: new Steps(
        render: render
        'wait-for-promises': wait_for_promises
      )
      'post-process': new Steps(
        'type:html':
          'layouts-enabled:true':
            'render-layout': render_layout
          'has-parent:false':
            'add-cheerio': add_cheerio
            'render-styles': render_styles
            'render-scripts': render_scripts
            'extract-from-cheerio': extract_from_cheerio
      )
  
  render: (filename, data = {}) ->
    opts = {}
    opts[k] = v for k, v of @opts
    opts.filename = filename
    opts.data = data
    opts.promises ?= []
    
    q()
    .then => @steps['pre-process'].execute(opts)
    .then => @steps.render.execute(opts)
    .then => @steps['post-process'].execute(opts)
    .then -> opts

exports.Renderer = Renderer
