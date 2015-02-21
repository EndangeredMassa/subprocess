sub = require '../../src'
assert = require 'assertive'

processes = null

# if mocha crashes, the child process
# running our tests won't clean itself
# up properly; so, we have to do this
process.on 'uncaughtException', (error) ->
  sub.killAll(processes) if processes?
  console.error error.stack
  process.exit(1)

describe 'sub', ->
  afterEach ->
    sub.killAll(processes) if processes?
    processes = null

  describe 'starts a process', ->
    before (done) ->
      config =
        app:
          command: 'node test/apps/service.js %port%'
          logFilePath: 'test/log/start-proc.log'
          port: 9903

      sub config, (error, _processes) =>
        processes = _processes
        @proc = processes?.app
        done(error)

    it 'has rawProcess.pid', ->
      assert.truthy 'process.rawProcess.pid', @proc.rawProcess.pid

    it 'has baseUrl', ->
      assert.equal 'process.baseUrl', 'http://127.0.0.1:9903', @proc.baseUrl

    it 'has port', ->
      assert.equal 'process.port', 9903, @proc.port

    it 'has logPath', ->
      assert.match 'process.logPath', /test\/log\/start-proc\.log$/, @proc.logPath

    it 'has logHandle', ->
      assert.equal 'process.logHandle', 'number', typeof @proc.logHandle

    it 'has launchCommand', ->
      assert.equal 'process.launchCommand', 'node', @proc.launchCommand

    it 'has launchArguments', ->
      assert.deepEqual 'process.launchArguments', ['test/apps/service.js', '9903'], @proc.launchArguments

    it 'has workingDirectory', ->
      assert.equal 'process.workingDirectory', 'string', typeof @proc.workingDirectory

  it 'allows custom verification', (done) ->
    forceError = new Error 'force failure'

    config =
      app:
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/custom-verification.log'
        port: 6501
        verify: (port, callback) ->
          callback(forceError)

    sub config, (error, _processes) ->
      processes = _processes
      try
        assert.equal forceError, error
        done()
      catch testError
        done(testError)

  it 'passes along spawn options', (done) ->
    config =
      app:
        command: 'node test/apps/env-echo.js'
        logFilePath: 'test/log/spawn-opts.log'
        port: 9933
        verify: (port, callback) ->
          callback(null, true)
        spawnOpts:
          env:
            testResult: 100

    sub config, (error, _processes) ->
      processes = _processes
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
      ), 100

  it 'allows arbitrary verification timeouts', (done) ->
    config =
      app:
        command: 'node test/apps/hang.js'
        logFilePath: 'test/log/timeout.log'
        verifyTimeout: 10
        verify: (port, callback) ->
          callback(null, false) # not yet ready

    sub config, (error, _processes) ->
      processes = _processes
      try
        assert.include 'timeout: 10ms', error.message
        done()
      catch testError
        done(testError)

  it 'shows the log when a process errors', (done) ->
    config =
      app:
        command: 'node test/apps/error.js %port%'
        logFilePath: 'test/log/process-error.log'

    sub config, (error, _processes) ->
      processes = _processes
      try
        assert.include 'intentional failure', error.message
        done()
      catch testError
        done(testError)

  it 'starts dependant processes', (done) ->
    serviceReady = false

    config =
      app:
        dependsOn: ['service']
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/dep-app.log'
        port: 6500
        verify: (port, callback) ->
          return callback(new Error 'service not yet started') if !serviceReady
          callback(null, true)

      service:
        command: 'node test/apps/service.js %port%'
        logFilePath: 'test/log/dep-service.log'
        verify: (port, callback) ->
          serviceReady = true
          callback(null, true) # no error

    sub config, (error, _processes) ->
      processes = _processes
      done(error)

