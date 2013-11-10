class EngineError extends Error
  name: 'EngineError'
  constructor: (err, engine, opts, data) ->
    return new EngineError(err, engine, opts, data) unless @ instanceof EngineError
    
    @original_error = err
    # @engine = engine
    # @render_opts = opts
    # @render_data = data
    
    @filename = opts.filename
    @content = opts.content
    @template =
      type: engine.type
      extension: if Array.isArray(engine.extension) then engine.extension[0] or engine.extension

exports.engine = EngineError
