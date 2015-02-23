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

  child =
    rawProcess: spawn cmd, args, spawnOpts
    name: name
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

###
Copyright (c) 2015, Groupon, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

Neither the name of GROUPON nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

