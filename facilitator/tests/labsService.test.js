// Run with: node --test tests/labsService.test.js
const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const loggerPath = require.resolve('../src/utils/logger');
require.cache[loggerPath] = { id: loggerPath, filename: loggerPath, loaded: true, exports: { info() {}, warn() {}, error() {} } };

const { discoverLabs } = require('../src/services/labsService');

function tree(files) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'labs-'));
  for (const [file, content] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(root, file)), { recursive: true });
    fs.writeFileSync(path.join(root, file), typeof content === 'string' ? content : JSON.stringify(content));
  }
  return root;
}

test('discovers the exams of every category, sorted by category order then directory', () => {
  const root = tree({
    'b-cat/category.json': { name: 'Second', order: 2 },
    'b-cat/002/config.json': { lab: 'b-2', name: 'B two' },
    'b-cat/001/config.json': { lab: 'b-1', name: 'B one', description: 'd', difficulty: 'Easy', warmUpTimeInSeconds: 30, examDurationInMinutes: 60 },
    'a-cat/category.json': { name: 'First', order: 1 },
    'a-cat/001/config.json': { lab: 'a-1' },
  });
  const labs = discoverLabs(root);
  assert.deepStrictEqual(labs.map(l => l.id), ['a-1', 'b-1', 'b-2']);
  assert.deepStrictEqual(labs[1], {
    id: 'b-1', assetPath: 'assets/exams/b-cat/001', name: 'B one', category: 'Second',
    description: 'd', warmUpTimeInSeconds: 30, difficulty: 'Easy', examDurationInMinutes: 60,
  });
  assert.strictEqual(labs[0].name, 'a-1');
  assert.strictEqual(labs[0].difficulty, 'Medium');
});

test('the category name defaults to the directory name', () => {
  const root = tree({ 'plain/category.json': {}, 'plain/001/config.json': { lab: 'p-1' } });
  assert.strictEqual(discoverLabs(root)[0].category, 'plain');
});

test('directories without category.json, and exams without config.json or lab id, are ignored', () => {
  const root = tree({
    'nocat/001/config.json': { lab: 'x-1' },
    'cat/category.json': { name: 'Cat' },
    'cat/001/config.json': { lab: 'c-1' },
    'cat/002/answers.md': 'no config',
    'cat/003/config.json': { name: 'no lab id' },
    'cat/004/config.json': '{ not json',
  });
  assert.deepStrictEqual(discoverLabs(root).map(l => l.id), ['c-1']);
});

test('metadata that is valid JSON but not an object does not abort the discovery', () => {
  const root = tree({
    'null-cat/category.json': 'null',
    'null-cat/001/config.json': { lab: 'n-1' },
    'cat/category.json': {},
    'cat/001/config.json': 'null',
    'cat/002/config.json': '[1, 2]',
    'cat/003/config.json': { lab: 42 },
    'cat/004/config.json': { lab: 'ok' },
  });
  assert.deepStrictEqual(discoverLabs(root).map(l => l.id), ['ok']);
});

test('a duplicated lab id keeps the first exam only', () => {
  const root = tree({ 'cat/category.json': {}, 'cat/001/config.json': { lab: 'same' }, 'cat/002/config.json': { lab: 'same' } });
  assert.strictEqual(discoverLabs(root).length, 1);
});

test('the real exams directory is discovered', () => {
  const labs = discoverLabs(path.join(__dirname, '..', 'assets', 'exams'));
  assert.ok(labs.length > 0);
  for (const lab of labs) assert.ok(fs.existsSync(path.join(__dirname, '..', lab.assetPath, 'config.json')), lab.id);
});
