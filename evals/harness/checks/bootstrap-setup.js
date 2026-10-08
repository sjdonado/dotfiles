// bootstrap-setup: round 1 writes grounded portable instructions; round 2 runs the
// check and leaves the instructions alone. Round is inferred from the seed.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { git } = require('./state');
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const read = (p) => { try { return fs.readFileSync(path.join(dir, p), 'utf8'); } catch (e) { return ''; } };
  const seeds = meta.seedFiles || {};
  const guidance = read('AGENTS.md');
  const grounded = !!guidance && guidance.includes('make check');
  const nested = seeds['src/AGENTS.md'] === undefined || crypto.createHash('sha256').update(read('src/AGENTS.md')).digest('hex') === seeds['src/AGENTS.md'];
  const personal = ['yolo', 'ponytail', 'proto skill', '.agent/', 'openspec'].some(w => guidance.toLowerCase().includes(w));
  const seedHasGuidance = Object.keys(seeds).includes('AGENTS.md');
  const checks = { grounded, nested, personal: !personal };
  if (!seedHasGuidance) {
    checks.created = !!guidance;
  } else {
    const same = crypto.createHash('sha256').update(guidance).digest('hex') === seeds['AGENTS.md'];
    checks.stable = same;
    checks.ran = fs.existsSync(path.join(dir, '.check-ran'));
  }
  const pass = Object.values(checks).every(Boolean);
  return { pass, score: +pass, reason: JSON.stringify(checks) };
};
