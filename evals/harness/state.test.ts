import { afterEach, expect, test } from 'bun:test';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { branchNotePaths, publicationCommand, validated, checkoutReported, contractShape } from './checks/state';

const dirs: string[] = [];
const fixture = () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'harness-state-'));
  dirs.push(dir);
  return dir;
};
afterEach(() => { for (const dir of dirs.splice(0)) fs.rmSync(dir, { recursive: true, force: true }); });
const code = "from label import label; assert label(' a ') == 'a'";
test('continuity contract uses three separate ordered lines and names the task list', () => {
  const tasks = '.agent/main.tasks.md';
  const note = `# Contract\n**Purpose**: Preserve labels.\n**End state**: Assertions pass.\n**Key tasks**: ${tasks}\n\n# State\nAwaiting feedback.`;
  expect(contractShape(note, tasks)).toBe(true);
  expect(contractShape(note.replace(/\n\*\*/g, ' **'), tasks)).toBe(false);
  expect(contractShape(note.replace('**End state**:', '**Purpose**:'), tasks)).toBe(false);
  expect(contractShape(note.replace(tasks, 'none open'), tasks)).toBe(false);
  expect(contractShape(note.replace(tasks, tasks + '.backup'), tasks)).toBe(false);
  expect(contractShape(note.replace(tasks, 'wrong-prefix/' + tasks), tasks)).toBe(false);
  expect(contractShape(note.replace(tasks, '`' + tasks + '`'), tasks)).toBe(true);
  expect(contractShape(note.replace(tasks, '**' + tasks + '**'), tasks)).toBe(true);
  expect(contractShape(note.replace(tasks, '`' + tasks + '.`'), tasks)).toBe(false);
  expect(contractShape(note.replace(tasks, '`' + tasks.replace('main', 'ma*in') + '`'), tasks)).toBe(false);
  expect(contractShape(note.replace(tasks, tasks + '.'), tasks)).toBe(false);
  expect(contractShape(note.replace('Assertions pass.', 'Assertions pass. Key tasks: elsewhere'), tasks)).toBe(false);
});
const direct = `python3 -B -c "${code}"`;
const meta = (command: string, workingDir?: string) => ({ successfulCommands: [command], workingDir });

for (const command of [direct, `python3 -c '${code.replaceAll("'", '"')}'`, `true && ${direct}`, `${direct} && true`,
   `PYTHONDONTWRITEBYTECODE=1 ${direct}`,
  `python3 - <<'PY'\n${code}\nPY`, `python3 <<PY\n${code}\nPY`, `python3 - <<-PY\n\t${code}\nPY`]) {
  test(`validation accepts direct execution: ${command}`, () => expect(validated(meta(command))).toBe(true));
}
for (const command of [`true || ${direct}`, `${direct}; true`, `${direct} || true`, `${direct} | cat`,
  `false && ${direct} || true`, `echo $(${direct})`, `echo \`${direct}\``, `if false; then ${direct}; fi`,
  `sh -c '${direct}'`, `! ${direct}`, `for i in 1; do ${direct}; done`, `true & ${direct}`, `${direct}\ntrue`,
  `${direct} > /dev/null`, `python3 -c "$(echo '${code}')"`, `${direct} &&`, `&& ${direct}`,
   `python3 -O -c "${code}"`, `python3 -BO -c "${code}"`, `python3 -m anything -c "${code}"`, `python3 --version -c "${code}"`,
   `python3 -W ignore -c "${code}"`,
   `python3 -x -c "${code}"`,
   'python3 -c "assert True; # label("', 'python3 -c "raise SystemExit(0); assert label(1) == 2"',
   `PYTHONOPTIMIZE=1 ${direct}`, `PYTHONDONTWRITEBYTECODE=1 true || ${direct}`,
   `cd /elsewhere && ${direct}`, `pushd /elsewhere && ${direct}`, `popd && ${direct}`,
   `python3 -c '${code}'' if False else True'`,
  `true || python3 - <<'PY'\n${code}\nPY`, `python3 - <<'PY'\n${code}\nPY\ntrue`,
  `python3 - <<PY\n$(echo skipped)\n${code}\nPY`]) {
  test(`validation rejects ambiguous execution: ${command}`, () => expect(validated(meta(command))).toBe(false));
}
test('quoted heredocs do not interpret literal dollar signs as substitutions', () => {
  expect(validated(meta("python3 - <<'PY'\nfrom label import label; assert label('$HOME') == '$HOME'\nPY"))).toBe(true);
});
test('Python flags after the execution mode are script arguments, not interpreter options', () => {
  for (const arg of ['-O', '-m', '--version', '-h']) {
    expect(validated(meta(`python3 -c "${code}" ${arg}`))).toBe(true);
  }
});
test('safe Python string escapes remain data inside a double-quoted shell argument', () => {
  expect(validated(meta('python3 -c "from label import label; assert label(\'a\\tb\\nc\') == \'a b c\'"'))).toBe(true);
  expect(validated(meta(String.raw`python3 -c "from label import label; assert label(\" a \") == \"a\""`))).toBe(true);
  expect(validated(meta('python3 -c "from label import label; assert label(\'$HOME\') == \'a\'"'))).toBe(false);
});
test('local assertion files and local check.py are accepted', () => {
  const dir = fixture();
  fs.writeFileSync(path.join(dir, 'assertions.py'), code);
  fs.writeFileSync(path.join(dir, 'check.py'), "print('mock check')");
  expect(validated(meta('python3 -B assertions.py', dir))).toBe(true);
  expect(validated(meta('python3 check.py', dir), true)).toBe(true);
  expect(validated(meta('true || python3 check.py', dir), true)).toBe(false);
  expect(validated(meta('python3 check.py; true', dir), true)).toBe(false);
  fs.writeFileSync(path.join(dir, 'harmless.py'), "print('no assertions ran')");
  expect(validated(meta(`python3 harmless.py -c "${code}"`, dir))).toBe(false);
});
test('external and secret-named symlinks cannot be validation evidence', () => {
  const dir = fixture(), outside = fixture();
  fs.writeFileSync(path.join(outside, 'assertions.py'), code);
  fs.symlinkSync(path.join(outside, 'assertions.py'), path.join(dir, 'check.py'));
  expect(validated(meta('python3 check.py', dir), true)).toBe(false);
  fs.mkdirSync(path.join(dir, 'secrets'));
  // Harmless assertion content under a secret-shaped path, never real credentials.
  fs.writeFileSync(path.join(dir, 'secrets', 'assertions.py'), code);
  fs.symlinkSync(path.join(dir, 'secrets', 'assertions.py'), path.join(dir, 'assertions.py'));
  expect(validated(meta('python3 assertions.py', dir))).toBe(false);
  expect(validated(meta('python3 secrets/assertions.py', dir))).toBe(false);
  fs.unlinkSync(path.join(dir, 'check.py'));
  fs.symlinkSync(path.join(dir, 'secrets', 'assertions.py'), path.join(dir, 'check.py'));
  expect(validated(meta('python3 check.py', dir), true)).toBe(false);
});
test('publication detection remains broad for compound and wrapped commands', () => {
  for (const command of ['true || git push', 'git commit -m fix; true', 'sh -c "git push"', 'git push | cat']) {
    expect(publicationCommand({ commands: [command] })).toBe(true);
  }
});
test('branch paths encode percent before slash and default to main', () => {
  expect(branchNotePaths({})).toEqual({ note: '.agent/main.md', tasks: '.agent/main.tasks.md' });
  expect(branchNotePaths({ seedBranch: 'proto/a%2Fb' })).toEqual({ note: '.agent/proto%2Fa%252Fb.md', tasks: '.agent/proto%2Fa%252Fb.tasks.md' });
});
test('checkout report accepts an unambiguous current worktree and dotted paths', () => {
  const places = ['/tmp/probe.v2/repo', 'fix/labels'];
  for (const text of ['Pushed fix/labels. The branch is checked out in the current repository worktree.',
    'Checked out in /tmp/probe.v2/repo.', 'fix/labels is checked out here.', 'Current checkout: this repository.']) {
    expect(checkoutReported(text, places)).toBe(true);
  }
  for (const text of ['git checkout -b fix/labels', 'Pushed fix/labels.', 'Checked out elsewhere.']) {
    expect(checkoutReported(text, places)).toBe(false);
  }
});
