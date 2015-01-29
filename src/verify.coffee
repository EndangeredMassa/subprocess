{readFileSync} = require 'fs'

getLogWithQuote = (proc) ->
  logQuote =
    try
      createTailQuote readFileSync(proc.metadata.logPath, 'utf8'), 20
    catch err
      "(failed to load log: #{err.message})"

  """
  Log output (last 20 lines):

  #{logQuote}

  See the full log at: #{proc.metadata.logPath}
  """

procCrashedError = (proc) ->
  message =
    """
    Process \"#{proc.name}\" crashed with code #{proc.exitCode}.
    #{getLogWithQuote proc}
    """
  message += "\n#{proc.error.trim()}" if proc.error?.length > 0
  new Error message

niceTime = (ms) ->
  if ms > 1000 * 60
    "#{ms / 1000 / 60}min"
  else if ms > 1000
    "#{ms / 1000}s"
  else
    "#{ms}ms"

createTailQuote = (str, count) ->
  lines = str.split('\n').slice(-count)
  "> #{lines.join '\n> '}"

procTimedoutError = (proc, port, timeout) ->
  formatArguments = (args = []) ->
    return '(no arguments)' unless args.length
    args.join('\n           ')

  message =
    """
    Process \"#{proc.name}\" did not start in time.

    Debug info:
    * command: #{proc.metadata.launchCommand}
               #{formatArguments proc.metadata.launchArguments}
    * cwd:     #{proc.metadata.workingDirectory}
    * port:    #{port}
    * timeout: #{niceTime timeout}
    ```

    #{getLogWithQuote proc}
    """
  message += "\n#{proc.error.trim()}" if proc.error?.length > 0
  new Error message

module.exports = (proc, validate, interval, timeout, port, callback) ->
  if proc.exitCode?
    error = procCrashedError(proc)
    return callback(error)

  procName = proc.name

  startTime = Date.now()

  check = ->
    # debug 'Checking for %s on port %s', procName, port
    validate port, (error) ->
      if proc.rawProcess.exitCode?
        error = procCrashedError(proc)
        return callback(error)

      if error?
        if (Date.now() - startTime) >= timeout
          return callback(procTimedoutError proc, port, timeout)
        setTimeout(check, 100)
      else
        callback()

  check()

