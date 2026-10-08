// feedback-approved-batch: the approved batch commits, pushes, refreshes the PR.
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as crypto from 'node:crypto';
import { git, json, operations, behavior, validated } from './state';
export default (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const head = git(dir, 'rev-parse', 'HEAD');
  const read = (p) => { try { return fs.readFileSync(path.join(dir, p), 'utf8'); } catch (e) { return ''; } };
  const pr = json(dir, 'pr.json', {});
  const body = `${pr.title || ''}\n${pr.body || ''}`;
  const notePath = '.agent/proto%2Fhandoff.md', note = read(notePath);
  const seedNote = Object.keys(meta.seedFiles || {}).find(f => f.endsWith('proto%2Fhandoff.md'));
  const pushed = !!meta.seedHead && head !== meta.seedHead &&
    git(dir, 'ls-remote', 'origin').split('\n').some(line => line.split(/\s/)[0] === head);
  const checks = {
    behavior: behavior(dir, 'Draft'),
    committed: !!meta.seedHead && head !== meta.seedHead,
    pushed,
    edited: operations(dir).some(e => e.served && e.args.slice(0, 2).join(' ') === 'pr edit'),
    noteRefreshed: !!note && !!seedNote && crypto.createHash('sha256').update(note).digest('hex') !== meta.seedFiles[seedNote],
    current: body.toLowerCase().includes('draft'),
    humanContext: body.includes('Human context: keep the release checklist.'),
    validated: validated(meta),
  };
  const pass = Object.values(checks).every(Boolean);
  return { pass, score: +pass, reason: JSON.stringify(checks) };
};
