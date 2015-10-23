{spawn} = require 'child_process'
fs = require 'fs'

###
# The only reliable way to ensure that children are properly cleaned up
# is to make them actively quit when the parent goes away.
# Since we don't have direct control over what the children do,
# we insert an extra layer between this process and the actual child:
#
#  [ Current Process ]
#          ᴧ
#          | IPC channel
#          V
#     [ wrap.js ]
#          |
#          | forks
#          V
#    [ Actual Child ]
#
# The moment this process dies, the IPC channel to `wrap.js` gets disconnected.
# `wrap.js` reacts to this by stopping the actual child process and then itself.
#
# The assumption here is that `wrap.js` is "sufficiently simple" that it won't
# quit unexpectedly without getting around to the cleanup first.
###
WRAPPER = require.resolve './wrap.js'

interpolatePort = (port) ->
  (arg) ->
    arg.replace '%port%', port

module.exports = (name, command, commandArgs, port, logPath, logHandle, spawnOpts) ->
  commandArgs = commandArgs.map(interpolatePort port)
  nodeArgs = [ WRAPPER, command ].concat commandArgs

  child =
    rawProcess: spawn process.execPath, nodeArgs, spawnOpts
    name: name
    baseUrl: "http://127.0.0.1:#{port}"
    port: port
    logPath: logPath
    logHandle: logHandle
    launchCommand: command
    launchArguments: commandArgs
    workingDirectory: spawnOpts.cwd

  child.readLog = (callback) ->
    fs.readFile logPath, (error, data) ->
      return callback(error) if error?
      callback null, data.toString()

  # This means the wrap.js process failed. This *should* never happen.
  child.rawProcess.on 'error', (err) ->
    err.message = "[subprocess internal] #{err}"
    child.error = err
    child.rawProcess.kill()

  child

