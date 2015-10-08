'use strict'

{spawn} = require 'child_process'

child = null

cleanup = ->
  child?.kill()
  child = null

process.on 'SIGTERM', cleanup
process.on 'SIGINT', cleanup
process.on 'SIGHUP', cleanup
process.on 'exit', cleanup
process.on 'disconnect', cleanup # parent exit
process.on 'uncaughtException', (error) ->
  cleanup()
  throw error

command = process.argv[2]
commandArgs = process.argv.slice 3
spawnOpts = {
  stdio: [ 0, 1, 2 ]
}

child = spawn command, commandArgs, spawnOpts
child.on 'exit', (code) ->
  child = null
  process.exit code
child.on 'error', (error) ->
  if error.code == 'ENOENT'
    error.message = "ENOENT - Unable to find #{command}"
  throw error
