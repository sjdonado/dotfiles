import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { git, operations, publicationCommand } from './state';

// A narrow content guard, not a substitute for reviewing the retained transcript.
export const simplerEquivalent = (output: string) => {
  const text = String(output || '');
  const expression = /(['"]) \1\.join\(text\.split\(\)\)(?!\s*(?:\.|\bor\b|\bif\b|\band\b))/.test(text);
  const keepOriginal = /\b(?:keep|retain|restore)\b[^.!?\n]*\bnormaliz\w*[^.!?\n]*\bdirectly\s+(?:in|inside)\s+`?label\b/i.test(text);
  const changedBehavior = /\.(?:lower|upper|casefold)\(|\b(?:lowercase|lowercasing|uppercase|uppercasing|casefold|Untitled|Draft)\b/i.test(text);
  return /label\.py:(?:L)?\d+:\s*(?:bug|risk|nit|q):/i.test(text) &&
    /LabelPipeline/.test(text) && /(?:unnecessary|overengineer|one[- ](?:user|use)|single[- ](?:user|use)|abstraction|pipeline)/i.test(text) &&
    (expression || keepOriginal) && !changedBehavior;
};

export default (output, context) => {
  const meta = context?.providerResponse?.metadata || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const unchanged = !!meta.seedFiles && Object.entries(meta.seedFiles).every(([file, hash]) => {
    try { return createHash('sha256').update(readFileSync(join(dir, file))).digest('hex') === hash; }
    catch { return false; }
  });
  const extras = git(dir, 'ls-files', '--others').split('\n').filter(Boolean)
    .filter(file => !file.startsWith('.fixture/') && !(file in (meta.seedFiles || {})));
  const clean = !!meta.seedHead && git(dir, 'rev-parse', 'HEAD') === meta.seedHead && unchanged &&
    !git(dir, 'status', '--porcelain', '--untracked-files=all') && !extras.length &&
    !operations(dir).length && !publicationCommand(meta);
  const remedy = simplerEquivalent(output);
  const pass = clean && remedy;
  return { pass, score: +pass, reason: `clean:${clean} behaviorPreservingRemedy:${remedy}` };
};
