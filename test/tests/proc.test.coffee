sub = require '../../src'
assert = require 'assertive'

describe 'sub', ->
  beforeEach ->
    @timeout 3000

  it 'starts a process'
  it 'allows custom verification'

  it 'passes along spawn options', (done) ->
    processes =
      app:
        command: 'node test/apps/env-echo.js'
        logFilePath: 'test/log/spawn-opts.log'
        verify: (port, callback) ->
          callback(null)
        spawnOpts:
          env:
            testResult: 100

    sub processes, (error, processes) ->
      return done(error) if error?

      # wait a little bit for the process
      # to actually write out to the log file;
      # yes, arbitrary delays are bad
      setTimeout ( ->
        processes.app.readLog (error, log) ->
          return done(error) if error?
          assert.include '100', log
          done()
      ), 50

  it 'allows arbitrary verification timeouts', (done) ->
    processes =
      app:
        command: 'node test/apps/hang.js'
        logFilePath: 'test/log/timeout.log'
        verifyTimeout: 10

    sub processes, (error, processes) ->
      assert.include 'timeout: 10ms', error.message
      done()

  it 'shows the log when a process errors', (done) ->
    processes =
      app:
        command: 'node test/apps/error.js %port%'
        logFilePath: 'test/log/process-error.log'

    sub processes, (error, processes) ->
      assert.include 'intentional failure', error.message
      done()

  it 'starts dependant processes', (done) ->
    # TODO: test that one starts before the other
    processes =
      app:
        dependsOn: ['service']
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/dep-app.log'
        port: 6500

      service:
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/dep-service.log'
        verify: (port, callback) ->
          callback(null) # no error

    sub processes, (error, processes) ->
      done(error)

