path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs'

module.exports = (cwd, logPath, callback) ->
  filename = path.resolve cwd, logPath
  dirname = path.dirname filename
  flags = 'w'

  mkdirp dirname, (error) ->
    return callback(error) if error?

    fs.open filename, flags, (error, fd) ->
      return callback(error, {}) if error?
      callback null, {filename, fd}

