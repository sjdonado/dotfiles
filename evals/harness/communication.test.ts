import { afterEach, expect, test } from 'bun:test';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import check from './checks/communication';

const dirs: string[] = [];
afterEach(() => { for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true }); });
const run = (args) => {
  const dir = mkdtempSync(join(tmpdir(), 'communication-check-')); dirs.push(dir);
  mkdirSync(join(dir, '.fixture'));
  writeFileSync(join(dir, '.fixture/operations.jsonl'), args.map(a => JSON.stringify({ args: a, served: true })).join('\n'));
  return check('', { providerResponse: { metadata: { workingDir: dir } } });
};
test('file and stdin message bodies pass; title-only edits and reads need no body', () => {
  expect(run([['pr', 'create', '--body-file', 'body.md'], ['issue', 'comment', '86', '--body-file', '-'],
    ['pr', 'edit', '7', '--title', 'title'], ['pr', 'view', '--json', 'body']]).pass).toBe(true);
});
test('inline or absent message bodies fail even when later corrected', () => {
  for (const args of [[['pr', 'create', '--body', 'inline']], [['issue', 'comment', '86', '--body', 'inline']],
    [['pr', 'edit', '7', '--body', 'inline']], [['pr', 'create']],
    [['pr', 'create', '--body', 'inline'], ['pr', 'edit', '--body-file', 'body.md']]]) expect(run(args).pass).toBe(false);
});
test('served usage probes are read-only, not message writes', () => {
  expect(run([['pr', 'create', '--help'], ['issue', 'comment', '86', '-h'], ['pr', 'edit', '7', '--help']]).pass).toBe(true);
  expect(run([['pr', 'create', '--help'], ['pr', 'create', '--body', 'inline']]).pass).toBe(false);
});
