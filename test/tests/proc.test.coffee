sub = require '../../src'
assert = require 'assertive'

describe 'sub', ->
  # TODO
  #afterEach (done) ->
  #  @processes.killAll(done)

  it 'starts a process', (done) ->
    processes =
      app:
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/start-proc.log'

    sub processes, (error, processes) ->
      try
        assert.falsey 'error', error
        assert.falsey 'process.exitCode', processes.app.rawProcess.exitCode
        assert.truthy 'process.pid', processes.app.rawProcess.pid
        done()
      catch testError
        done(testError)

  it 'allows custom verification', (done) ->
    forceError = new Error 'force failure'

    processes =
      app:
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/custom-verification.log'
        port: 6501
        verify: (port, callback) ->
          callback(forceError)

    sub processes, (error, processes) ->
      try
        assert.equal error, forceError
        done()
      catch testError
        done(testError)

  it 'passes along spawn options', (done) ->
    processes =
      app:
        command: 'node test/apps/env-echo.js'
        logFilePath: 'test/log/spawn-opts.log'
        port: 9933
        verify: (port, callback) ->
          callback(null, true)
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
          try
            assert.include '100', log
            done()
          catch testError
            done(testError)
      ), 50

  it 'allows arbitrary verification timeouts', (done) ->
    processes =
      app:
        command: 'node test/apps/hang.js'
        logFilePath: 'test/log/timeout.log'
        verifyTimeout: 10
        verify: (port, callback) ->
          callback(null, false) # not yet ready

    sub processes, (error, processes) ->
      try
        assert.include 'timeout: 10ms', error.message
        done()
      catch testError
        done(testError)

  it 'shows the log when a process errors', (done) ->
    processes =
      app:
        command: 'node test/apps/error.js %port%'
        logFilePath: 'test/log/process-error.log'

    sub processes, (error, processes) ->
      try
        assert.include 'intentional failure', error.message
        done()
      catch testError
        done(testError)

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
          callback(null, true) # no error

    sub processes, (error, processes) ->
      done(error)

