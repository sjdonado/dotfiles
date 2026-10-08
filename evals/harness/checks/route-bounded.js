// route-bounded: full specified slice ships (code + commit + push + PR + report).
const { git, json, operations, behavior, validated } = require('./state');
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const head = git(dir, 'rev-parse', 'HEAD'), branch = git(dir, 'branch', '--show-current');
  const pr = json(dir, 'pr.json', {}), log = operations(dir);
  const remoteHead = git(dir, 'ls-remote', 'origin', `refs/heads/${branch}`).split(/\s/)[0];
  const sentences = String(output || '').toLowerCase().split(/[.!?\n]/);
  const checks = {
    behavior: behavior(dir, 'Untitled'), committed: !!meta.seedHead && head !== meta.seedHead,
    committedLabel: git(dir, 'ls-files', '--error-unmatch', 'label.py') === 'label.py' && !git(dir, 'diff', 'HEAD', '--', 'label.py'),
    validated: validated(meta),
    nonDefaultBranch: !!branch && branch !== 'main' && branch !== 'master', pushed: head === remoteHead,
    prCreated: log.filter(e => e.served && e.args.slice(0, 2).join(' ') === 'pr create').length === 1,
    prOnPushedBranch: pr.headRefName === branch && pr.state === 'OPEN',
    pushedBeforePr: !!head && pr.remoteHeadAtCreation === head,
    noMerge: !log.some(e => e.args.slice(0, 2).join(' ') === 'pr merge'),
    checkoutReported: sentences.some(sentence => /(checkout|checked out)/.test(sentence) &&
      [dir, branch].some(place => place && sentence.includes(place.toLowerCase()))),
  };
  const pass = Object.values(checks).every(Boolean);
  return { pass, score: +pass, reason: JSON.stringify(checks) };
};
