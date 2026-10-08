// external: grounded reply plus close, local check ran, no tracked edits.
const fs = require('fs');
const path = require('path');
const { git, json, operations, validated } = require('./state');
module.exports = (output, context) => {
  const meta = (context && context.providerResponse && context.providerResponse.metadata) || {};
  const dir = meta.workingDir || process.env.PF_CHECK_DIR || '.';
  const issue = json(dir, 'issue.json', {});
  const replies = (issue.comments || []).filter(c => c.author?.login === 'agent');
  const text = replies.length === 1 ? replies[0].body : '';
  const lowered = text.toLowerCase();
  const grounded = ['cheerio', '7.29.1', 'websocket'].every((w) => lowered.includes(w)) &&
    /(transitive|indirect|through cheerio|via cheerio|cheerio\s+(?:requests|pulls|depends on)\s+undici)/.test(lowered);
  const citations = ['package.json', 'bun.lock', 'src/client.ts'].every(p => text.includes(p));
  const prose = !/[\u2013\u2014]/.test(text);
  const adjacent = /\b(4|four)\b/.test(lowered) && lowered.includes('title') &&
    /\b(only|sole)\b/.test(lowered) && /\b(detail|details|description|report)\b/.test(lowered) &&
    /\b(clarify|provide|share|correct|update|rename|change|need|request|list)\b/.test(lowered);
  const served = operations(dir).filter(e => e.served).map(e => e.args.slice(0, 2).join(' '));
  const view = served.indexOf('issue view'), comment = served.indexOf('issue comment'), close = served.indexOf('issue close');
  const closed = issue.state === 'CLOSED' && 0 <= view && view < comment && comment < close;
  const ran = fs.existsSync(path.join(dir, '.check-ran')) && validated(meta, true);
  const unedited = !!meta.seedHead && git(dir, 'rev-parse', 'HEAD') === meta.seedHead &&
    !git(dir, 'diff', meta.seedHead, '--', '.', ':!.fixture') && !git(dir, 'diff', '--cached', meta.seedHead, '--', '.', ':!.fixture');
  const pass = grounded && citations && prose && adjacent && closed && ran && unedited;
  return { pass, score: pass ? 1 : 0, reason: `grounded:${grounded} citations:${citations} prose:${prose} adjacent:${adjacent} closed:${closed} ran:${ran} unedited:${unedited}` };
};
