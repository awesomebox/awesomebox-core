fs = require 'fs'
path = require 'path'
engines = require './engines'

class Tree
  constructor: (root) ->
    @root = root.replace(/\/$/, '')
    @__map()
  
  __map: ->
    tree = {}
  
    read_dir = (dir) =>
      fs.readdirSync(dir).map (file) =>
        return if file[0] is '.'
        file_path = path.join(dir, file)
        relative_path = file_path.slice(@root.length).replace(/\/_/g, '/')
        if fs.statSync(file_path).isDirectory()
          tree[relative_path] = read_dir(file_path)
        else
          tree[relative_path] = file_path
      
        relative_path
    
    tree['/'] = read_dir(@root)
    @tree = tree
  
  subtree: (root_path) ->
    real_path = @tree[root_path.replace(/\/$/, '')]
    return null unless real_path?
    new Tree(real_path)
  
  exists: (file_path) ->
    @tree[file_path]?
  
  is_dir: (file_path) ->
    @exists(file_path) and Array.isArray(@tree[file_path])
  
  real_path: (file_path) ->
    @tree[file_path]
  
  real_relative_path: (file_path) ->
    @tree[file_path].slice(@root.length)
  
  find: (dir_path, opts) ->
    dir_path = '/' + dir_path.replace(/(^\/|\/$)/g, '').trim()
    
    return null unless @exists(dir_path)
    
    for file in @tree[dir_path] when not @is_dir(file)
      o = exports.parse_filename(file)
      return file if o.base is opts.base and o.type is opts.type
    null

exports.directory_tree = (root) -> new Tree(root)

exports.parse_filename = (filename) ->
  filename = path.basename(filename)
  res =
    type: ''
    base: filename
    engines: []
  
  [res.base, exts...] = filename.split('.')
  exts = exts.reverse()
  
  res.engines.push(exts.shift()) while exts.length and engines.by_ext[exts[0]]?
  
  if exts.length and engines.by_type[exts[0]]?
    res.type = exts.shift()
  else if res.engines.length > 0
    res.type = engines.by_ext[res.engines[0]].type
  else
    res.type = 'html'
  
  res.engines = res.engines.reverse()
  res.base = [res.base].concat(exts.reverse()).join('.')
  
  res

exports.find_file = (root, relative_path, opts = {}) ->
  relative_path = '/' + relative_path.replace(/^\//, '').replace(/\/_/g, '/').trim()
  tree = new Tree(root)
  
  o = exports.parse_filename(relative_path)
  base = o.base.replace(/^_/, '')
  type = opts.type or o.type
  
  if relative_path is '/'
    res = tree.find('/', base: 'index', type: type)
  else
    relative_dir = path.dirname(relative_path)
    res = tree.find(relative_dir, base: base, type: type) or
      tree.find(path.join(relative_dir, base), base: 'index', type: type)
  
  if res? then tree.real_relative_path(res) else null

search_dirs = (full_path) ->
  res = []
  while full_path isnt '/'
    full_path = path.dirname(full_path)
    res.push(full_path)
  res

exports.find_layout_file = (root, template_relative_path, opts = {}) ->
  template_relative_path = '/' + template_relative_path.replace(/^\//, '').trim()
  tree = new Tree(root)
  
  if tree.exists('/layouts')
    if opts.layout
      layout = opts.layout.replace(/(^\/|\/$)/g, '')
      res = tree.find('/layouts', base: layout, type: 'html')
      throw new Error('Could not find layout ' + layout + ' specified in ' + template_relative_path) unless res?
    else
      dirs = search_dirs(template_relative_path)
      for d in dirs
        layout = path.basename(d)
        res = tree.find('/layouts', base: layout or 'default', type: 'html')
        break if res?
  
  if res? then tree.real_relative_path(res) else null
