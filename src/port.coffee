{createServer} = require 'net'
portscanner = require 'portscanner'

isAvailable = (port, callback) ->
  portscanner.checkPortStatus port, '127.0.0.1', (error, status) ->
    return callback(error) if error?
    callback null, (status == 'closed')

findOpen = (port, callback) ->
  port ?= 0
  server = createServer()
  server.on 'error', (error) ->
    error.message = "Checking port #{port}:\n"  +error.message
    callback(error)
  server.listen port, ->
    port = @address().port
    server.on 'close', -> callback(null, port)
    server.close()

module.exports = {isAvailable, findOpen}

