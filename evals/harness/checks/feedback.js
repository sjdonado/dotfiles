// feedback: Draft fallback lands, PR edited, human context kept, note pending.
const { git, json, operations, behavior, validated } = require('./state');
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const head = git(dir, 'rev-parse', 'HEAD');
  const log = operations(dir).filter(e => e.served).map(e => e.args);
  const pr = json(dir, 'pr.json', {});
  const body = `${pr.title || ''}\n${pr.body || ''}`;
  const checks = {
    behavior: behavior(dir, 'Draft'),
    committed: !!meta.seedHead && head !== meta.seedHead,
    pushed: !!meta.seedHead && head !== meta.seedHead &&
      git(dir, 'ls-remote', 'origin').split('\n').some(line => line.split(/\s/)[0] === head),
    readPrState: log.some(op => op.slice(0, 2).join(' ') === 'pr view'),
    noForbidden: operations(dir).every(e => ['pr view', 'pr list', 'pr checks', 'pr edit'].includes(e.args.slice(0, 2).join(' ')) || e.args[0] === '--version'),
    prEdited: log.some(op => op.slice(0, 2).join(' ') === 'pr edit'),
    prCurrent: body.toLowerCase().includes('draft'),
    humanContext: body.includes('Human context: keep the release checklist.') && body.includes('https://example.invalid/issues/7'),
    validated: validated(meta),
  };
  const pass = Object.values(checks).every(Boolean);
  return { pass, score: +pass, reason: JSON.stringify(checks) };
};
