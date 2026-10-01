// Safe pipeline demo fixture. Run with: node --test test/failing-test.example.cjs
const test = require('node:test');
const assert = require('node:assert/strict');
test('intentional failure demonstration', () => assert.equal('demo', 'expected-value'));
