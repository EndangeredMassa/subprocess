# subprocess

subprocess is a child process management library for Node.js.
It handles startup, port management, availability checking, and teardown
of a series of child processes.

It's like an [`async.auto`](https://github.com/caolan/async#auto)
for processes.

## install

```bash
npm install --save subprocess
```

## usage

```js
var subprocess = require('subprocess');

var processes = {
  processName: {
    dependsOn: ['<other proc name>', ...],  // optional
    command: 'node index.js --port=%port%', // %port% is populated with the port
    port: 9999,                             // omit to get a random available port
    logPath: './log/process.log',           // file path to log file for stdio
    spawnOptions: {},                       // options to pass to child_process.spawn

    verifyInterval: 100,                    // ms, default
    verifyTimeout: 3000,                    // ms, default
    verify: function(port, callback){       // optional, defaults to checking
      // custom verification logic          //   for port availablility
      callback(isAvailable);
    }
  }
};

subprocess(processes, function(errors, processes){
  // `errors` is an array of objects describing any errors, if any;
  // each item is in the form:
  // {
  //   name: '<processName>',
  //   error: <some error object>
  // }

  // `processes` is a hash of process names to process objects
});
```

All processes started this way will be
automatically registered to kill themselves
on `process.on('uncaughtException', handler)`.

## example

```js
var subprocess = require('subprocess');
var request = require('request');

var processes = {
  app: {
    dependsOn: ['service'],
    command: 'node index.js --port=%port%',
    port: 4500
  },

  service: {
    command: 'node service.js --port=%port%',
    verify: function(port, callback){
      request('http://localhost:'+port+'/status', function(error, response, body){
        callback(!error && response.statusCode == 200);
      });
    }
  }
};

subprocess(processes, function(errors, processes){
  if (errors.length > 0) {
    errors.forEach(function(error){
      console.error(error);
    });
    process.exit(1);
  }

  console.log('processes started successfully!');
});
```

