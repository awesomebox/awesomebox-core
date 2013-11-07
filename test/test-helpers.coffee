path = require 'path'
assert = require 'assert'
{helpers} = require '../'

describe 'Helpers', ->
  
  describe 'parse_filename', ->
    
    it 'should parse HTML filenames', ->
      assert.deepEqual(
        helpers.parse_filename('foo.bar.baz')
        {
          type: 'html'
          base: 'foo.bar.baz'
          engines: []
        }
      )
      
      assert.deepEqual(
        helpers.parse_filename('foo.html.ejs')
        {
          type: 'html'
          base: 'foo'
          engines: ['ejs']
        }
      )
      
      assert.deepEqual(
        helpers.parse_filename('foo.ejs.jade')
        {
          type: 'html'
          base: 'foo'
          engines: ['ejs', 'jade']
        }
      )
      
      assert.deepEqual(
        helpers.parse_filename('foo')
        {
          type: 'html'
          base: 'foo'
          engines: []
        }
      )
      
      assert.deepEqual(
        helpers.parse_filename('/path/to/file/foo.ejs')
        {
          type: 'html'
          base: 'foo'
          engines: ['ejs']
        }
      )
    
    it 'should parse CSS filenames', ->
      assert.deepEqual(
        helpers.parse_filename('/main.css.less')
        {
          type: 'css'
          base: 'main'
          engines: ['less']
        }
      )
      
      assert.deepEqual(
        helpers.parse_filename('foo.less')
        {
          type: 'css'
          base: 'foo'
          engines: ['less']
        }
      )
      
      assert.deepEqual(
        helpers.parse_filename('stylesheets/main.css')
        {
          type: 'css'
          base: 'main'
          engines: []
        }
      )
      
    it 'should parse JS filenames', ->
      assert.deepEqual(
        helpers.parse_filename('/main.js.coffee')
        {
          type: 'js'
          base: 'main'
          engines: ['coffee']
        }
      )
    
      assert.deepEqual(
        helpers.parse_filename('foo.coffee')
        {
          type: 'js'
          base: 'foo'
          engines: ['coffee']
        }
      )
    
      assert.deepEqual(
        helpers.parse_filename('javascripts/main.js')
        {
          type: 'js'
          base: 'main'
          engines: []
        }
      )
  
  describe 'find_file', ->
    
    it 'should find the correct file', ->
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/')
        '/index.html.ejs'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/index')
        '/index.html.ejs'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/index.html')
        '/index.html.ejs'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/foo')
        '/foo.html.ejs'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/foo.html')
        '/foo.html.ejs'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/bar')
        null
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/bar.css')
        '/bar/index.css.less'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/bar/index.css')
        '/bar/index.css.less'
      )
    
      assert.equal(
        helpers.find_file(path.join(__dirname, 'content'), '/foo/bar/team', type: 'data')
        '/foo/bar/team.json'
      )
  
  describe 'find_layout_file', ->
    
    it 'should find the correct layout', ->
      
      assert.equal(
        helpers.find_layout_file(path.join(__dirname, 'content'), '/index.html.ejs')
        '/_layouts/default.html.ejs'
      )
      
      assert.equal(
        helpers.find_layout_file(path.join(__dirname, 'content'), '/foo/bar/baz/zoo.html')
        '/_layouts/default.html.ejs'
      )
