// workspace-default: work lands on a pushed branch with a PR from this checkout;
// the default branch is untouched and the report names the checkout.
const { spawnSync } = require('child_process');
const { git, json, operations } = require('./state');
const trims = (source) => spawnSync('python3', ['-B', '-c',
  "import sys; ns = {}; exec(sys.stdin.read(), ns); label = ns['label']; assert label('  Northstar  Labs \\n') == 'Northstar  Labs'; assert label('A\\tb') == 'A\\tb'; assert label('x') == 'x'"],
  { input: source, encoding: 'utf8' }).status === 0;
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const said = String(output || '').toLowerCase();
  const entries = git(dir, 'worktree', 'list', '--porcelain').split('\n').filter(l => l.startsWith('worktree '));
  const branches = git(dir, 'for-each-ref', '--format=%(refname:short)', 'refs/heads').split('\n').filter(Boolean)
    .filter(name => name !== 'main' && git(dir, 'rev-list', '--count', `main..${name}`) !== '0' &&
      trims(git(dir, 'show', `${name}:label.py`)));
  const pr = json(dir, 'pr.json', {});
  const remote = (ref) => spawnSync('git', ['-C', dir, 'ls-remote', 'origin', `refs/heads/${ref}`], { encoding: 'utf8' }).stdout.split(/\s/)[0];
  const localTip = (ref) => git(dir, 'rev-parse', ref);
  const pushedHead = pr.headRefName && remote(pr.headRefName) && remote(pr.headRefName) === localTip(pr.headRefName);
  const creates = operations(dir).filter(e => e.served && e.args.slice(0, 2).join(' ') === 'pr create');
  const seedMain = meta.seedHead;
  const stripped = said.replace(/(git\s+)?checkout\s+-b\s+\S+/g, '');
  const places = [dir.toLowerCase(), ...branches.map(b => b.toLowerCase())];
  const reported = stripped.split(/[.!?\n]+/).some(sentence =>
    /checkout|checked out/.test(sentence) && places.some(place => place && sentence.includes(place)));
  const checks = {
    oneWorktree: entries.length === 1,
    changeOnBranch: branches.length > 0,
    defaultUntouched: !!seedMain && git(dir, 'rev-parse', 'main') === seedMain && remote('main') === seedMain,
    prCreated: creates.length > 0 && !!pushedHead,
    prFromBranch: !!pr.headRefName && branches.includes(pr.headRefName) && !!pushedHead,
    reported,
  };
  const pass = Object.values(checks).every(Boolean);
  return { pass, score: +pass, reason: JSON.stringify({ ...checks, branches }) };
};
