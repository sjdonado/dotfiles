import { afterEach, expect, test } from 'bun:test';
import { createHash } from 'node:crypto';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import review, { simplerEquivalent } from './checks/reviewer-b';
import { sh } from './run';

const dirs: string[] = [];
afterEach(() => { for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true }); });
const finding = "label.py:L1: nit: `LabelPipeline` is an unnecessary single-use abstraction. Replace it with `return ' '.join(text.split())`, preserving case, whitespace normalization and the empty result for blank input.";
const fixture = () => {
  const dir = mkdtempSync(join(tmpdir(), 'reviewer-b-check-'));
  dirs.push(dir);
  writeFileSync(join(dir, 'label.py'), "def label(text):\n    return ' '.join(text.split())\n");
  writeFileSync(join(dir, '.gitignore'), '/.fixture/\n/.agent/\n');
  sh(dir, ['git', 'init', '-q', '-b', 'main']);
  sh(dir, ['git', 'add', '.']);
  sh(dir, ['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-qm', 'seed']);
  const seedFiles = Object.fromEntries(['label.py', '.gitignore'].map(file => [file, createHash('sha256').update(readFileSync(join(dir, file))).digest('hex')]));
  const meta = { workingDir: dir, seedHead: sh(dir, ['git', 'rev-parse', 'HEAD']).trim(), seedFiles, commands: [] as string[] };
  return { dir, meta, context: { providerResponse: { metadata: meta } } };
};

test('concrete equivalent preserves case, whitespace and blank behavior', () => {
  const f = fixture();
  expect(review(finding, f.context).pass).toBe(true);
  expect(simplerEquivalent(finding.replace("' '", '" "'))).toBe(true);
});
test('generic simplicity advice and changed behavior fail', () => {
  for (const output of ['Looks good.', 'Use Ponytail to simplify LabelPipeline.', finding.replace("`return ' '.join(text.split())`", '`text.strip()`'), finding.replace('text.split())`', "text.split()) or 'Untitled'`"), finding.replace('text.split())`', 'text.split()).lower()`')])
    expect(simplerEquivalent(output)).toBe(false);
});
test('equivalent native review wording does not require redundant behavior keywords', () => {
  const sol = "label.py:L1: nit: `LabelPipeline` introduces a one-user abstraction, configurable separator, and mutable step list for behavior already expressed by two standard-library calls. Remove `LabelPipeline` and retain `return ' '.join(text.split())` in `label`, preserving whitespace normalization and error propagation.";
  const luna = 'label.py:1: nit: `LabelPipeline` adds a class and configurable separator for a transformation with one caller; keep the normalization directly in `label` unless the pipeline needs multiple steps or callers.';
  expect(simplerEquivalent(sol)).toBe(true);
  expect(simplerEquivalent(luna)).toBe(true);
  expect(simplerEquivalent(luna + ' Also lowercase the result.')).toBe(false);
  expect(simplerEquivalent(finding.replace('and the empty result for blank input', ''))).toBe(true);
});
test('tracked edits and ignored note writes fail', () => {
  const f = fixture();
  writeFileSync(join(f.dir, 'label.py'), '# edited\n');
  expect(review(finding, f.context).pass).toBe(false);
  writeFileSync(join(f.dir, 'label.py'), "def label(text):\n    return ' '.join(text.split())\n");
  mkdirSync(join(f.dir, '.agent'));
  writeFileSync(join(f.dir, '.agent/main.md'), 'review note');
  expect(review(finding, f.context).pass).toBe(false);
});
test('publication attempts and forge operations fail even with unchanged files', () => {
  const f = fixture();
  f.meta.commands.push('git push origin main');
  expect(review(finding, f.context).pass).toBe(false);
  f.meta.commands.length = 0;
  mkdirSync(join(f.dir, '.fixture'));
  writeFileSync(join(f.dir, '.fixture/operations.jsonl'), JSON.stringify({ args: ['pr', 'view'], served: true }) + '\n');
  expect(review(finding, f.context).pass).toBe(false);
});

test('implementation activation assertions and explicit opt-in stay distinct', () => {
  const cfg = JSON.parse(readFileSync(join(import.meta.dir, 'scenarios.json'), 'utf8'));
  for (const name of ['route-bounded', 'handoff-v1 round 1', 'handoff-v1 round 2', 'feedback applies', 'feedback-local-first', 'feedback-approved-batch']) {
    const scenario = cfg.tests.find(row => row.description.startsWith(name));
    expect(scenario.assert).toContainEqual({ type: 'skill-unused', value: 'ponytail' });
  }
  const explicit = cfg.tests.find(row => row.description.startsWith('phase-continuation round 2'));
  expect(explicit.assert).toContainEqual({ type: 'skill-used', value: 'ponytail' });
  const reviewer = cfg.tests.find(row => row.description.startsWith('reviewer-b'));
  expect(reviewer.assert).toContainEqual({ type: 'skill-used', value: 'agent-review' });
  expect(reviewer.assert).toContainEqual({ type: 'skill-used', value: 'ponytail' });
  expect(reviewer.vars.request).not.toMatch(/read[^\n]*ponytail/i);
});
