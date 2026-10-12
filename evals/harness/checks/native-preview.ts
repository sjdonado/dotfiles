// Native tool acknowledgements and completed HTTP checks, not prose claims.
import { validationCommands, pythonArguments } from './state';
const directHTTP = (words, url) => {
  const curl = /(?:^|\/)curl$/.test(words[0]), wget = /(?:^|\/)wget$/.test(words[0]);
  if (!curl && !wget) return false;
  let target = false;
  for (let i = 1; i < words.length; i++) {
    const word = words[i];
    if (word === url) { if (target) return false; target = true; continue; }
    if (curl && (/^-[fsSL]+$/.test(word) || ['--fail', '--silent', '--show-error', '--location'].includes(word))) continue;
    if (wget && ['-q', '-qO-', '--quiet', '--output-document=-'].includes(word)) continue;
    if (wget && ['-O', '--output-document'].includes(word) && words[i + 1] === '-') { i++; continue; }
    if ((curl && ['--max-time', '--connect-timeout'].includes(word)) || (wget && ['--timeout', '--tries'].includes(word))) {
      if (!/^\d+(?:\.\d+)?$/.test(words[++i] || '')) return false;
      continue;
    }
    if (/^--(?:max-time|connect-timeout|timeout|tries)=\d+(?:\.\d+)?$/.test(word)) continue;
    // Unknown options may disable requests, forge output, or consume the apparent URL.
    return false;
  }
  return target;
};
export const registeredLaunch = (part) => {
  const state = part.state, metadata = state.metadata?.metadata;
  return state.status === 'completed' && state.input.background === true && metadata?.status === 'running' &&
    typeof metadata.shellID === 'string' && state.output?.includes(metadata.shellID);
};
export const checkedReadiness = (part, url, marker) => {
  const state = part.state;
  if (state.status !== 'completed') return false;
  if (part.tool === 'execute') return !!state.output?.includes(marker) &&
    !!state.metadata?.metadata?.toolCalls?.some(call => call.tool === 'fetch' && call.status === 'completed' && call.input?.url === url);
  if (part.tool !== 'shell' || state.metadata?.metadata?.exit !== 0) return false;
  const commands = validationCommands(state.input.command || '');
  if (commands.length !== 1) return false;
  return commands.some(({ words }) => {
    if (directHTTP(words, url)) return !!state.output?.includes(marker);
    const code = pythonArguments(words)?.code;
    // Support a direct, branch-free urllib assertion; other scripts need transcript review.
    if (!code) return false;
    const request = code.match(/^import\s+urllib\.request;\s*(\w+)\s*=\s*urllib\.request\.urlopen\((['"])(.*?)\2(?:\s*,\s*timeout=\d+)?\);\s*(\w+)\s*=\s*\1\.read\(\)\.decode\(\);\s*/);
    if (!request || request[3] !== url) return false;
    const check = code.slice(request[0].length).match(/^assert\s+(\w+)\.status\s*==\s*200\s+and\s+(\w+)\s*==\s*(['"])(.*?)\3(?:\s*,\s*\(\1\.status,\s*\2\))?(?:\s*;\s*print\((['"])[^'"]*\5\))?\s*$/);
    return !!check && check[1] === request[1] && check[2] === request[4] && check[4] === marker;
  });
};
