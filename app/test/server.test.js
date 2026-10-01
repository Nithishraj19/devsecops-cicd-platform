'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const { setTimeout: delay } = require('node:timers/promises');
test('health, version, application, and not-found routes respond correctly', async (t) => {
  const port = 3100 + Math.floor(Math.random() * 1000);
  const child = spawn(process.execPath, ['src/server.js'], { cwd: __dirname + '/..', env: { ...process.env, PORT: String(port), APP_VERSION: 'test-1.2.3', NODE_ENV: 'test' }, stdio: 'ignore' });
  t.after(() => child.kill('SIGTERM'));
  let ready = false;
  for (let attempt = 0; attempt < 40; attempt++) {
    try { await fetch(`http://127.0.0.1:${port}/health`); ready = true; break; } catch { await delay(50); }
  }
  assert.equal(ready, true, 'server starts');
  assert.deepEqual(await fetch(`http://127.0.0.1:${port}/health`).then((r) => r.json()), { status: 'UP', version: 'test-1.2.3' });
  assert.deepEqual(await fetch(`http://127.0.0.1:${port}/version`).then((r) => r.json()), { version: 'test-1.2.3', environment: 'test' });
  assert.equal((await fetch(`http://127.0.0.1:${port}/`).then((r) => r.json())).service, 'devsecops-demo-api');
  assert.equal((await fetch(`http://127.0.0.1:${port}/missing`)).status, 404);
});
