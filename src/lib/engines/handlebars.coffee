exports.type = 'html'
exports.extension = 'handlebars'

# probably need to do something here with registerHelper and registerPartial
# maybe there can be a config directory with named files that can extend engines...


# /_config/handlebars.coffee

# module.exports = (handlebars) ->
#   handlebars.registerHelper 'link_to', (title, options) ->
#     "<a href=\"/posts#{@url}\">#{title}!</a>"
#   handlebars.registerPartial('link', '<a href="/people/{{id}}">{{name}}</a>')

exports.process = (opts, data) ->
  handlebars = require 'handlebars'
  handlebars.compile(opts.content.toString(), data)(data)
