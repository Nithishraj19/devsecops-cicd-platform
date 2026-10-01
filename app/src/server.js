'use strict';
const http = require('node:http');
const { URL } = require('node:url');
const version = process.env.APP_VERSION || require('../package.json').version;
const port = Number(process.env.PORT || 3000);
let draining = false;
function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', 'content-length': Buffer.byteLength(payload), 'cache-control': 'no-store' });
  res.end(payload);
}
const server = http.createServer((req, res) => {
  const started = Date.now();
  const url = new URL(req.url, 'http://localhost');
  let status = 200;
  if (url.pathname === '/health') {
    status = draining ? 503 : 200;
    sendJson(res, status, { status: draining ? 'DRAINING' : 'UP', version });
  } else if (url.pathname === '/version') {
    sendJson(res, 200, { version, environment: process.env.NODE_ENV || 'development' });
  } else if (url.pathname === '/') {
    sendJson(res, 200, { service: 'devsecops-demo-api', message: 'Secure delivery, verified.', version, links: ['/health', '/version'] });
  } else {
    status = 404;
    sendJson(res, status, { error: 'not_found' });
  }
  console.log(JSON.stringify({ level: 'info', event: 'http_request', method: req.method, path: url.pathname, status, duration_ms: Date.now() - started }));
});
server.listen(port, '0.0.0.0', () => console.log(JSON.stringify({ level: 'info', event: 'server_started', port, version })));
function shutdown(signal) {
  if (draining) return;
  draining = true;
  console.log(JSON.stringify({ level: 'info', event: 'shutdown_started', signal }));
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 10000).unref();
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
