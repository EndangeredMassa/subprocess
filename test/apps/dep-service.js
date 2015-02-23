var net = require('net');
var port = process.argv[2];
var servicePort = process.argv[3];

var server = net.createServer(function(c) {
    c.write('hello\r\n');
    c.pipe(c);
});

server.listen(port, function() {
});

console.log(servicePort);

