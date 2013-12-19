path = require 'path'
assert = require 'assert'
{helpers} = require '../src'

describe 'Helpers', ->
  
  describe 'parse_filename', ->
    
    it 'foo.bar.baz', ->
      assert.deepEqual(
        helpers.parse_filename('foo.bar.baz')
        {
          type: ''
          base: 'foo.bar.baz'
          engines: []
        }
      )
    it 'foo.html.ejs', ->
      assert.deepEqual(
        helpers.parse_filename('foo.html.ejs')
        {
          type: 'html'
          base: 'foo'
          engines: ['ejs']
        }
      )
    it 'foo.ejs.jade', ->
      assert.deepEqual(
        helpers.parse_filename('foo.ejs.jade')
        {
          type: 'html'
          base: 'foo'
          engines: ['ejs', 'jade']
        }
      )
    it 'foo', ->
      assert.deepEqual(
        helpers.parse_filename('foo')
        {
          type: ''
          base: 'foo'
          engines: []
        }
      )
    it '/path/to/file/foo.ejs', ->
      assert.deepEqual(
        helpers.parse_filename('/path/to/file/foo.ejs')
        {
          type: 'html'
          base: 'foo'
          engines: ['ejs']
        }
      )
    
    it '/main.css.less', ->
      assert.deepEqual(
        helpers.parse_filename('/main.css.less')
        {
          type: 'css'
          base: 'main'
          engines: ['less']
        }
      )
    it 'foo.less', ->
      assert.deepEqual(
        helpers.parse_filename('foo.less')
        {
          type: 'css'
          base: 'foo'
          engines: ['less']
        }
      )
    it 'stylesheets/main.css', ->
      assert.deepEqual(
        helpers.parse_filename('stylesheets/main.css')
        {
          type: 'css'
          base: 'main'
          engines: []
        }
      )
      
    it '/main.js.coffee', ->
      assert.deepEqual(
        helpers.parse_filename('/main.js.coffee')
        {
          type: 'js'
          base: 'main'
          engines: ['coffee']
        }
      )
    it 'foo.coffee', ->
      assert.deepEqual(
        helpers.parse_filename('foo.coffee')
        {
          type: 'js'
          base: 'foo'
          engines: ['coffee']
        }
      )
    it 'javascripts/main.js', ->
      assert.deepEqual(
        helpers.parse_filename('javascripts/main.js')
        {
          type: 'js'
          base: 'main'
          engines: []
        }
      )
    it 'javascripts/main.js', ->
      assert.deepEqual(
        helpers.parse_filename('foo.txt')
        {
          type: ''
          base: 'foo.txt'
          engines: []
        }
      )
  
  describe 'find_file', ->
    
    it '/', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/')
        '/index.html.ejs'
      )
    it '/index', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/index')
        '/index.html.ejs'
      )
    it '/index.html', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/index.html')
        '/index.html.ejs'
      )
    it '/foo', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/foo')
        '/foo.html.ejs'
      )
    it '/foo.html', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/foo.html')
        '/foo.html.ejs'
      )
    it '/bar', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/bar')
        null
      )
    it '/bar.css', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/bar.css')
        '/bar/index.css.less'
      )
    it '/bar/index.css', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/bar/index.css')
        '/bar/index.css.less'
      )
    it '/foo/bar/team {type: data}', ->
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/foo/bar/team', type: 'data')
        '/foo/bar/team.json'
      )
  
  describe 'find_layout_file', ->
    
    it '/index.html.ejs', ->
      assert.equal(
        helpers.find_layout_file(path.join(__dirname, 'content'), '/index.html.ejs')
        '/_layouts/default.html.ejs'
      )
    it '/foo/bar/baz/zoo.html', ->
      assert.equal(
        helpers.find_layout_file(path.join(__dirname, 'content'), '/foo/bar/baz/zoo.html')
        '/_layouts/default.html.ejs'
      )
