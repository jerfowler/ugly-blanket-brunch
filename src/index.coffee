fs = require 'fs'
async = require 'async'
blkt = require 'blanket'
uglify = require 'uglify-js'

module.exports = class Blanket
    brunchPlugin: yes
    type: 'javascript'

    constructor: (@config) ->
        @blanket = pattern: /app\.js$/, options: {}
        @uglify = pattern: /(vendor|app)\.js$/, fromString: yes

        if typeof @config?.plugins?.blanket == 'object'
            @blanket[key] = value for key, value of @config.plugins.blanket

        blkt.options "data-cover-flags": @blanket.options

        if typeof @config?.plugins?.uglify == 'object'
            @uglify[key] = value for key, value of @config.plugins.uglify

    optimize: (data, path, callback) =>
        async.parallel [
            (next) =>
                return callback null, data unless @blanket.pattern.test path
                blkt.instrument {inputFile: data, inputFileName: path}, (result) ->
                    name = path.replace /\.js$/, '.cov.js'
                    fs.writeFile name, result, next
            (next) =>
                return callback null, data unless @uglify.pattern.test path
                try
                    result = uglify.minify data, @uglify
                    name = path.replace /\.js$/, '.min.js'
                    fs.writeFile name, result, next
                catch err
                    next err
        ], (err, res) ->
            callback err, data
