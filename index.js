const http = require('http');

const server = http.createServer((req, res) => {
    console.log(`Received request: ${req.method} ${req.url}`);
  if (req.url === '/health') {
    res.writeHead(200);
    res.end('healthy');
    return;
  }

  res.writeHead(200);
  res.end('Hello World!');
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Server running at http://0.0.0.0:3000/');
});

process.on('SIGTERM', () => {
  server.close(() => {
    console.log('Server shutting down');
  });
});