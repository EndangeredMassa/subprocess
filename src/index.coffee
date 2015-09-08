portscanner = require 'portscanner'
async = require 'async'
{merge, clone} = require 'lodash'
port = require './port'

openLogFile = require './log'
spawn = require './spawn'
verify = require './verify'


convert = (proc) ->
  proc = merge {}, defaults(proc.name), proc
  proc.spawnOpts.cwd ?= process.cwd()

  (callback) ->
    openLogFile proc.spawnOpts.cwd, proc.logFilePath, (error, results) ->
      return callback(error) if error?
      {fd: logHandle, filename: logPath} = results

      spawnOpts =
        stdio: [ 'ignore', logHandle, logHandle ]
        env: clone(process.env)
      merge spawnOpts, proc.spawnOpts

      port.findOpen proc.port, (error, availablePort) ->
        return callback(error) if error?

        child = spawn(proc.name, proc.command, proc.commandArgs, availablePort, logPath, logHandle, spawnOpts)

        verify child, proc.verify, proc.verifyInterval, proc.verifyTimeout, availablePort, (error) ->
          return callback(error) if error?
          callback(null, child)


autoable = (name, proc) ->
  proc.name = name
  func = convert(proc)

  if proc.dependsOn?.length > 0
    array = clone(proc.dependsOn)
    array.push(func)
    array
  else
    func

defaults = (procName) ->
  port: 0 # get random available port
  logFilePath: "./log/#{procName}.log"
  spawnOpts: {}
  verifyInterval: 100
  verifyTimeout: 3000
  verify: (port, callback) ->
    portscanner.checkPortStatus port, '127.0.0.1', (error, status) ->
      return callback(error) if error?
      return callback(null, false) if status == 'closed'

      callback(null, true)

subprocess = (processConfig, callback) ->
  config = {}
  for key in Object.keys(processConfig)
    config[key] = autoable(key, processConfig[key])

  async.auto config, (error, procs) ->
    return callback(error) if error?
    callback(null, procs)

subprocess.killAll = (procs) ->
  for key, value of procs
    value.rawProcess.kill()

module.exports = subprocess

