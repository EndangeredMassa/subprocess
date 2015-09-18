{spawn} = require 'child_process'
fs = require 'fs'

killAllProcs = (procs) ->
  procs.forEach (proc) ->
    try
      proc.rawProcess.kill()
    catch err
      console.error err.stack
  procs = []

allProcs = []
registered = false
registerUncaughtHandler = (proc) ->
  allProcs.push(proc)

  if !registered
    process.on 'uncaughtException', (error) ->
      killAllProcs(allProcs)
      throw error

    process.on 'exit', ->
      killAllProcs(allProcs)

    registered = true


procNotFoundError = (error, cmd) ->
  error.message = "Unable to find #{cmd}"
  error

processPorts = {}
interpolatePorts = (args, processName, port) ->
  processPorts["#{processName}.port"] = port
  args.map (arg) ->
    arg = arg.replace '%port%', port

    arg.replace /%([^%]+)%/, (m, key) ->
      if processPorts[key]
        processPorts[key]
      else
        throw new Error "Invalid placeholder in #{processName}'s argument list: %#{key}%"

    for procKey, procPort of processPorts
      arg = arg.replace procKey, procPort
    arg

module.exports = (name, command, commandArgs, port, logPath, logHandle, spawnOpts) ->
  commandArgs = interpolatePorts(commandArgs, name, port)

  child =
    rawProcess: spawn command, commandArgs, spawnOpts
    name: name
    baseUrl: "http://127.0.0.1:#{port}"
    port: port
    logPath: logPath
    logHandle: logHandle
    launchCommand: command
    launchArguments: commandArgs
    workingDirectory: spawnOpts.cwd

  registerUncaughtHandler(child)

  child.readLog = (callback) ->
    fs.readFile logPath, (error, data) ->
      return callback(error) if error?
      callback null, data.toString()

  child.rawProcess.on 'error', (err) ->
    if err.errno is 'ENOENT'
      child.error = procNotFoundError(err, command).stack
    child.rawProcess.kill()

  child

