through = require('through')
_ = require("underscore")
minify = require("html-minifier").minify
path = require('path')

default_options =
    extensions: ['tpl', 'html']
    templateSettings: {}
    htmlMinifier: false
    requires: []

transform = (instance_opts) ->
    instance_opts = _.extend({}, default_options, instance_opts || {})

    return (file, opts) ->
        options = _.extend({}, instance_opts, opts || {})
        if typeof(options['extensions']) is 'string'
          options['extensions'] = options['extensions'].split ','

        isTemplate = _.some options.extensions, (ext) ->
            path.extname(file) is '.'+ext

        return through() if not isTemplate
        buffer = ""

        return through(
            (chunk) ->
                buffer += chunk.toString()
        ,
            () ->
                compiled = "";
                if options.requires.length
                    compiled = _.reduce(options.requires, (s, r) ->
                        if r.variable and r.module
                            s += 'var ' + r.variable + ' = require("' + r.module + '");' + "\n"
                        s
                    , '')
                html = buffer.toString()
                if options.htmlMinifier
                    html = minify(html, options.htmlMinifier)
                try
                    jst = _.template(
                        html,
                        undefined,
                        options.templateSettings
                        ).source;
                catch e
                    @emit('error', e)
                
                compiled += "module.exports = " + jst + ";\n";
                @queue(compiled)
                @queue(null)
        )

module.exports = transform()
module.exports.transform = transform
