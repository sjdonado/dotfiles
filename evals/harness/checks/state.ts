import * as fs from 'node:fs';
import * as path from 'node:path';
import { spawnSync } from 'node:child_process';
const git = (dir, ...args) => {
  const result = spawnSync('git', args, { cwd: dir, encoding: 'utf8' });
  return result.status === 0 ? result.stdout.trim() : '';
};
const json = (dir, file, fallback) => {
  try { return JSON.parse(fs.readFileSync(path.join(dir, '.fixture', file), 'utf8')); }
  catch { return fallback; }
};
const operations = (dir) => {
  const file = path.join(dir, '.fixture/operations.jsonl');
  return fs.existsSync(file) ? fs.readFileSync(file, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse) : [];
};
const behavior = (dir, blank) => spawnSync('python3', ['-B', '-c',
  `from label import label; assert label('  Northstar   Labs  ') == 'Northstar Labs'; assert label('a\\tb\\nc') == 'a b c'; assert label('   ') == ${JSON.stringify(blank)}`], { cwd: dir }).status === 0;
// ponytail: shell words cover direct commands and heredocs, not arbitrary scripts; transcript review checks indirection.
const commandWords = (command) => {
  const source = command.replace(/(<<-?\s*(['"]?)(\w+)\2[^\n]*\n)[\s\S]*?\n\3(?:\n|$)/g, '$1\n');
  const words = source.match(/"(?:\\.|[^"\\])*"|'[^']*'|&&|\|\||[;|\n]|[^\s;|]+/g) || [];
  const commands = [[]];
  for (const word of words) {
    if (/^(?:&&|\|\||[;|\n])$/.test(word)) commands.push([]);
    else commands.at(-1).push(word.replace(/^(['"])([\s\S]*)\1$/, '$2'));
  }
  return commands.filter(words => words.length).flatMap(words => {
    while (/(?:^|\/)(command|env)$/.test(words[0] || '') || /^\w+=/.test(words[0])) words.shift();
    const shell = /(?:^|\/)(bash|sh|zsh)$/.test(words[0] || ''), i = words.findIndex(word => /^-[a-z]*c[a-z]*$/.test(word));
    return shell && i > 0 ? commandWords(words[i + 1] || '') : [words];
  });
};
const publicationCommand = (meta) => (meta.commands || []).flatMap(commandWords).some(words => {
  if (!/(?:^|\/)git$/.test(words[0] || '')) return false;
  let i = 1;
  while (words[i]?.startsWith('-')) i += ['-C', '-c', '--git-dir', '--work-tree'].includes(words[i]) ? 2 : 1;
  const verb = words[i], args = words.slice(i + 1);
  return ['push', 'commit', 'reset', 'update-ref'].includes(verb) ||
    (verb === 'branch' && args.length > 0 && !args.some(a => ['--show-current', '--list', '-l', '-a', '-r', '-v', '-vv'].includes(a))) ||
    (['checkout', 'switch'].includes(verb) && args.some(a => ['-b', '-B', '-c', '-C', '--create', '--force-create', '--orphan'].includes(a)));
});
const branchNotePaths = (meta) => {
  const key = (meta.seedBranch || 'main').replace(/%/g, '%25').replace(/\//g, '%2F');
  return { note: `.agent/${key}.md`, tasks: `.agent/${key}.tasks.md` };
};
const contractShape = (note, tasksPath, base = '.') => {
  const section = String(note || '').split(/^#{1,6}\s+Contract\s*$/im)[1]?.split(/^#{1,6}\s/m)[0];
  const lines = (section || '').split('\n').map(line => line.trim()).filter(Boolean);
  const token = (lines[2]?.split(/:\*{0,2}\s+/, 2)[1] || '').split(/\s/)[0];
  const reference = token.replace(/^(`{1,2}|\*{1,2})(.+)\1$/, '$2');
  return ['Purpose', 'End state', 'Key tasks'].every((label, i) =>
    new RegExp(`^(?:-\\s+)?\\*{0,2}${label}\\*{0,2}:\\*{0,2}\\s+\\S`).test(lines[i] || '') &&
    (lines[i].match(/(?:Purpose|End state|Key tasks)\*{0,2}:/g) || []).length === 1) &&
    !!tasksPath && !!reference && path.resolve(base, reference) === path.resolve(base, tasksPath);
};
const checkoutReported = (output, places) => String(output || '').toLowerCase()
  .replace(/(?:git\s+)?checkout\s+-b\s+\S+/g, '')
  .split(/[.!?](?:\s|$)|\n/).some(sentence => /checkout|checked out/.test(sentence) &&
    (places.some(place => place && sentence.includes(place.toLowerCase())) ||
      /\b(?:this|current)\s+(?:repository\s+)?(?:checkout|worktree)\b/.test(sentence)));
// Validation is deliberately narrower than publication detection: only simple commands
// joined by && prove that Python ran successfully. Reject shells, substitutions,
// redirects, pipes and control flow rather than infer their exit status. A terminal
// heredoc is supported for a single direct Python invocation, not compound scripts.
const validationCommands = (command) => {
  let source = command.trim(), code;
  const heredoc = source.match(/^([^\n]*?)\s*<<(-?)\s*(['"]?)(\w+)\3\s*\n([\s\S]*?)\n\4$/);
  if (heredoc) {
    source = heredoc[1];
    code = heredoc[2] ? heredoc[5].replace(/^\t+/gm, '') : heredoc[5];
    if (!heredoc[3] && /[$`\\]/.test(code)) return [];
  }
  const matches = [...source.matchAll(/"(?:\\.|[^"\\])*"|'[^']*'|&&|[^\s'"&]+/g)];
  // Adjacent fragments form one shell argument; this narrow parser does not concatenate them.
  if (matches.some((match, i) => i > 0 && match.index === matches[i - 1].index + matches[i - 1][0].length &&
      match[0] !== '&&' && matches[i - 1][0] !== '&&')) return [];
  const tokens = matches.map(match => match[0]);
  if (tokens.join('').replace(/\s/g, '') !== source.replace(/\s/g, '')) return [];
  const commands = [[]];
  for (const token of tokens) {
    if (token === '&&') { if (!commands.at(-1).length || code !== undefined) return []; commands.push([]); continue; }
    const quoted = /^['"]/.test(token);
    if ((!quoted && /[;|&<>()[\]{}$`#\\\n\r]/.test(token)) || (token[0] === '"' && /[$`]/.test(token))) return [];
    const value = quoted ? token.slice(1, -1) : token;
    commands.at(-1).push(token[0] === '"' ? value.replace(/\\(["\\])/g, '$1') : value);
  }
  if (/[\n\r]/.test(source.replace(/"(?:\\.|[^"\\])*"|'[^']*'/g, '')) ||
      commands.some(words => !words.length || /^(?:if|then|else|elif|fi|for|while|until|do|done|case|esac|function|!|time|exec|eval|exit|return|break|continue|set|trap|source|cd|pushd|popd|\.)$/.test(words[0]) || /(?:^|\/)(?:bash|sh|zsh)$/.test(words[0]))) return [];
  return commands.map(words => ({ words, code }));
};
const pythonArguments = (words) => {
  if (!/(?:^|\/)python(?:3(?:\.\d+)?)?$/.test(words[0] || '')) return undefined;
  const args = words.slice(1), index = args.findIndex(word => !word.startsWith('-') || ['-c', '-', '--'].includes(word));
  // Accept only no-argument interpreter flags; -W/-X consume operands and need a fuller parser.
  if (!args.slice(0, index < 0 ? args.length : index).every(word => /^-[bBdEIsSuqv]+$/.test(word))) return undefined;
  const mode = args[index];
  return { code: mode === '-c' ? args[index + 1] || '' : undefined,
    file: mode === '--' ? args[index + 1] : mode && !['-c', '-'].includes(mode) ? mode : undefined };
};
const assertionEvidence = (code) => {
  const result = spawnSync('python3', ['-B', path.join(import.meta.dir, 'python-validation.py')],
    { input: code, encoding: 'utf8', timeout: 5000 });
  if (result.status !== 0) return false;
  try { return JSON.parse(result.stdout).passed === true; } catch { return false; }
};
const validated = (meta, script = false) => (meta.successfulCommands || []).some(command => validationCommands(command.trim().replace(/^PYTHONDONTWRITEBYTECODE=1\s+/, '')).some(({ words, code: heredocCode }) => {
  const invocation = pythonArguments(words);
  if (!invocation) return false;
  const { file } = invocation;
  let code = invocation.code ?? heredocCode ?? '', localFile = false;
  if (invocation.code === undefined && file?.endsWith('.py') && meta.workingDir) {
    try {
      const base = fs.realpathSync(meta.workingDir), target = fs.realpathSync(path.resolve(base, file));
      const relative = path.relative(base, target), secret = /(?:^|[\/._-])(?:env|environment|secrets?)(?:[\/._-]|$)/i;
      if (relative.startsWith('..') || path.isAbsolute(relative) || secret.test(file) || secret.test(relative)) return false;
      code = fs.readFileSync(target, 'utf8'); localFile = true;
    } catch { return false; }
  }
  if (script && localFile && path.resolve(meta.workingDir, file) === path.resolve(meta.workingDir, 'check.py')) return true;
  return (localFile || invocation.code !== undefined || (heredocCode !== undefined && (!file || words.includes('-')))) &&
    assertionEvidence(code);
}));
export { git, json, operations, behavior, publicationCommand, validated, branchNotePaths, contractShape, checkoutReported, validationCommands, pythonArguments };
