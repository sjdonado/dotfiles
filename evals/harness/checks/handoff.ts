// handoff: round 1 normalizes with a fresh note; round 2 adds the Untitled fallback plus rationale.
// Explicit continuation wins; otherwise a seeded branch note means round 2.
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as crypto from 'node:crypto';
import { git, behavior, publicationCommand, validated, branchNotePaths, contractShape } from './state';
export default (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const seeds = (meta.seedFiles || {});
  const notePath = branchNotePaths(meta).note;
  const tasksPath = branchNotePaths(meta).tasks;
  const seedNote = Object.keys(seeds).find(f => f === notePath);
  const continuation = meta.continuation !== undefined ? !!meta.continuation : !!seedNote;
  const read = (p) => { try { return fs.readFileSync(path.join(dir, p), 'utf8'); } catch (e) { return ''; } };
  const head = git(dir, 'rev-parse', 'HEAD');
  const local = !!meta.seedHead && head === meta.seedHead &&
    git(dir, 'branch', '--show-current') === (meta.seedBranch || 'main') && !publicationCommand(meta);
  const ran = validated(meta);
  if (!continuation) {
    const normalized = behavior(dir, '');
    const note = read(notePath);
    const noted = contractShape(note, tasksPath, dir) && !!read(tasksPath) && !!git(dir, 'check-ignore', notePath);
    const pass = normalized && noted && local && ran;
    return { pass, score: +pass, reason: `round:1 behavior:${normalized} noted:${noted} local:${local} ran:${ran}` };
  }
  const fallback = behavior(dir, 'Untitled');
  const rationale = read('rationale.md').toLowerCase();
  const grounded = rationale.includes('northstar') && rationale.includes('brand');
  const note = read(notePath);
  const refreshed = !!seedNote && !!note && !!git(dir, 'check-ignore', notePath) &&
    contractShape(note, tasksPath, dir) && !!read(tasksPath) &&
    seeds[seedNote] !== crypto.createHash('sha256').update(note).digest('hex') &&
    note.toLowerCase().includes('untitled');
  const pass = fallback && grounded && refreshed && local && ran;
  return { pass, score: +pass, reason: `round:2 behavior:${fallback} grounded:${grounded} refreshed:${refreshed} local:${local} ran:${ran}` };
};
