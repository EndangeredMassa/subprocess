{spawn} = require 'child_process'
fs = require 'fs'

procNotFoundError = (error, cmd) ->
  error.message = "Unable to find #{cmd}"
  error

module.exports = (name, command, port, logPath, logHandle, spawnOpts) ->
  command = command.replace '\%port\%', port
  args = command.split(' ')
  cmd = args[0]
  args = args.slice(1)

  child = {}
  child.rawProcess = spawn cmd, args, spawnOpts
  child.name = name
  child.metadata =
    baseUrl: "http://127.0.0.1:#{port}"
    port: port
    logPath: logPath
    logHandle: logHandle
    launchCommand: cmd
    launchArguments: args
    workingDirectory: spawnOpts.cwd
  child.readLog = (callback) ->
    fs.readFile logPath, (error, data) ->
      return callback(error) if error?
      callback null, data.toString()

  child.rawProcess.on 'error', (err) ->
    if err.errno is 'ENOENT'
      child.error = procNotFoundError(err, cmd).stack
    child.rawProcess.kill()

  process.on 'exit', ->
    try child.rawProcess.kill()
    catch err
      console.error err.stack

  process.on 'uncaughtException', (error) ->
    try child.rawProcess.kill()
    catch err
      console.error err.stack
    throw error

  child

