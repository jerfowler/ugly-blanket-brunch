fs = require 'fs'
async = require 'async'
blkt = require 'blanket'
uglify = require 'uglify-js'

module.exports = class Blanket
    brunchPlugin: yes
    type: 'javascript'

    constructor: (@config) ->
        @blanket = pattern: /app\.js$/, options: {engineOnly: true}
        @uglify = pattern: /(vendor|app)\.js$/, fromString: yes

        if typeof @config?.plugins?.blanket == 'object'
            @blanket[key] = value for key, value of @config.plugins.blanket

        if typeof @config?.plugins?.uglify == 'object'
            @uglify[key] = value for key, value of @config.plugins.uglify

    optimize: (data, path, callback) =>
        async.parallel [
            (next) =>
                return next null unless @blanket.pattern.test path
                try
                    name = path.replace /\.js$/, '.cov.js'
                    blanket = blkt "data-cover-flags": @blanket.options
                    blanket.instrument {inputFile: data, inputFileName: path}, (result) ->
                        fs.writeFile name, result, next
                catch err
                    next err
            (next) =>
                return next null unless @uglify.pattern.test path
                try
                    name = path.replace /\.js$/, '.min.js'
                    result = uglify.minify data, @uglify
                    fs.writeFile name, result, next
                catch err
                    next err
        ], (err, res) ->
            callback err, data