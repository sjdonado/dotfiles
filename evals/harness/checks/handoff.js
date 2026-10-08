// handoff: round 1 normalizes with a fresh note; round 2 adds the Untitled fallback plus rationale.
// Round is inferred from the seed: a seeded branch note means round 2.
const fs = require('fs');
const path = require('path');
const { git, behavior, publicationCommand, validated } = require('./state');
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const text = String(output || '').toLowerCase();
  const seeds = (meta.seedFiles || {});
  const notePath = '.agent/proto%2Fhandoff.md';
  const seedNote = Object.keys(seeds).find(f => f.endsWith('proto%2Fhandoff.md'));
  const read = (p) => { try { return fs.readFileSync(path.join(dir, p), 'utf8'); } catch (e) { return ''; } };
  const head = git(dir, 'rev-parse', 'HEAD');
  const local = !!meta.seedHead && head === meta.seedHead &&
    git(dir, 'branch', '--show-current') === (meta.seedBranch || 'main') && !publicationCommand(meta);
  const ran = validated(meta);
  if (!seedNote) {
    const normalized = behavior(dir, '');
    const note = read(notePath);
    const noted = !!note && !!git(dir, 'check-ignore', notePath);
    const pass = normalized && noted && local && ran;
    return { pass, score: +pass, reason: `round:1 behavior:${normalized} noted:${noted} local:${local} ran:${ran}` };
  }
  const fallback = behavior(dir, 'Untitled');
  const rationale = read('rationale.md').toLowerCase();
  const grounded = rationale.includes('northstar') && rationale.includes('brand');
  const note = read(notePath).toLowerCase();
  const refreshed = !!note && note !== undefined && !!git(dir, 'check-ignore', notePath) &&
    seeds[seedNote] !== require('crypto').createHash('sha256').update(note).digest('hex') &&
    note.includes('untitled');
  const pass = fallback && grounded && refreshed && local && ran;
  return { pass, score: +pass, reason: `round:2 behavior:${fallback} grounded:${grounded} refreshed:${refreshed} local:${local} ran:${ran}` };
};
