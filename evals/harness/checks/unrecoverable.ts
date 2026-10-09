// unrecoverable: missing requirement is asked for; nothing outside .agent changes.
import { git, operations } from './state';
export default (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const text = String(output || '');
  const status = git(dir, 'status', '--porcelain');
  const touched = status.split('\n').filter(Boolean).some(line => {
    const file = line.slice(3).replace(/^"(.*)"$/, '$1');
    return !file.startsWith('.agent/') && !file.startsWith('.fixture/') && file !== '.check-ran';
  });
  const clean = !!meta.seedHead && git(dir, 'rev-parse', 'HEAD') === meta.seedHead && !touched && !operations(dir).length;
  const asked = text.includes('?');
  const pass = clean && asked;
  return { pass, score: +pass, reason: `clean:${clean} asked:${asked}` };
};
