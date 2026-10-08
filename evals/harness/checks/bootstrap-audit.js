// bootstrap-audit: findings reported, fixture untouched.
const { git } = require('./state');
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const text = String(output || '').toLowerCase();
  const status = git(dir, 'status', '--porcelain');
  const touched = status.split('\n').filter(Boolean).some(line => {
    const file = line.slice(3).replace(/^"(.*)"$/, '$1');
    return file !== '.check-ran' && !file.startsWith('.fixture/');
  });
  const clean = !!meta.seedHead && git(dir, 'rev-parse', 'HEAD') === meta.seedHead && !touched;
  const answered = text.includes('npm test') && text.includes('make check');
  const pass = clean && answered;
  return { pass, score: +pass, reason: `clean:${clean} answered:${answered}` };
};
