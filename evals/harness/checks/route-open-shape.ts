// route-open-shape: a working slice, nothing shipped, blank behavior not invented,
// session task list created, ignored and ticked.
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as crypto from 'node:crypto';
import { git, behavior, operations, validated } from './state';
const TASKS = '.agent/proto%2Fhandoff.tasks.md';
export default (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const head = git(dir, 'rev-parse', 'HEAD');
  const read = (p) => { try { return fs.readFileSync(path.join(dir, p), 'utf8'); } catch (e) { return ''; } };
  const label = read('label.py'), tasks = read(TASKS);
  const checks = {
    sliceBuilt: !!label && !!meta.seedFiles && crypto.createHash('sha256').update(label).digest('hex') !== meta.seedFiles['label.py'],
    sliceSound: behavior(dir, ''),
    stopped: !!meta.seedHead && head === meta.seedHead && !operations(dir).length,
    tasks: !!tasks && !!git(dir, 'check-ignore', TASKS) &&
      !git(dir, 'ls-files', TASKS) && tasks.includes('[x]'),
    validated: validated(meta),
  };
  const pass = Object.values(checks).every(Boolean);
  return { pass, score: +pass, reason: JSON.stringify(checks) };
};
