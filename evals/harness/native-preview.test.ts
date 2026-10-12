import { expect, test } from 'bun:test';
import { checkedReadiness, registeredLaunch } from './checks/native-preview';

const url = 'http://127.0.0.1:12345/', marker = 'preview-marker';
test('native background acknowledgement proves registration only with an actual shell ID', () => {
  const part = { tool: 'shell', state: { status: 'completed', input: { background: true },
    output: 'Command moved to the background (shell ID: sh_owned)', metadata: { metadata: { status: 'running', shellID: 'sh_owned' } } } };
  expect(registeredLaunch(part)).toBe(true);
  expect(registeredLaunch({ ...part, state: { ...part.state, input: { background: false } } })).toBe(false);
  expect(registeredLaunch({ ...part, state: { ...part.state, output: 'unknown shell' } })).toBe(false);
  expect(registeredLaunch({ ...part, state: { ...part.state, metadata: {} } })).toBe(false);
});
test('native readiness accepts shell and completed Code Mode fetch evidence', () => {
  const shell = { tool: 'shell', state: { status: 'completed', input: { command: `curl -fsS ${url}` }, output: marker,
    metadata: { metadata: { exit: 0 } } } };
  const execute = { tool: 'execute', state: { status: 'completed', input: { code: 'fetch preview' }, output: marker,
    metadata: { metadata: { toolCalls: [{ tool: 'fetch', status: 'completed', input: { url } }] } } } };
  expect(checkedReadiness(shell, url, marker)).toBe(true);
  expect(checkedReadiness(execute, url, marker)).toBe(true);
  expect(checkedReadiness({ ...execute, state: { ...execute.state, status: 'error' } }, url, marker)).toBe(false);
  expect(checkedReadiness({ ...execute, state: { ...execute.state, output: 'not ready' } }, url, marker)).toBe(false);
  expect(checkedReadiness(execute, 'http://127.0.0.1:23456/', marker)).toBe(false);
  expect(checkedReadiness({ ...execute, state: { ...execute.state, metadata: {} } }, url, marker)).toBeFalsy();
  expect(checkedReadiness({ ...shell, state: { ...shell.state, input: { command: `echo "${marker} ${url}"` } } }, url, marker)).toBe(false);
  expect(checkedReadiness({ ...shell, state: { ...shell.state, metadata: { metadata: { exit: 1 } } } }, url, marker)).toBe(false);
  for (const command of [`curl --version ${url} && echo ${marker}`, `curl --help ${url}`, `curl -V ${url}`,
    `curl -s -o /dev/null -w${marker} ${url}`, `curl --write-out=${marker} ${url}`, `wget --version ${url}`,
    `curl -fsS ${url} && echo ${marker}`, `curl --header ${url} http://127.0.0.1:9999/`,
    `curl "${url}""--silent"`]) {
    expect(checkedReadiness({ ...shell, state: { ...shell.state, input: { command } } }, url, marker)).toBe(false);
  }
  for (const command of [`curl --fail --silent --show-error --max-time 5 ${url}`, `wget -qO- ${url}`]) {
    expect(checkedReadiness({ ...shell, state: { ...shell.state, input: { command } } }, url, marker)).toBe(true);
  }
});
test('successful direct Python HTTP assertions count even without printing the marker', () => {
  const code = `import urllib.request; r = urllib.request.urlopen("${url}", timeout=5); body = r.read().decode(); assert r.status == 200 and body == "${marker}"; print("ready")`;
  const part = { tool: 'shell', state: { status: 'completed', input: { command: `python3 -c '${code}'` },
    output: 'ready', metadata: { metadata: { exit: 0 } } } };
  expect(checkedReadiness(part, url, marker)).toBe(true);
  expect(checkedReadiness({ ...part, state: { ...part.state, input: { command: `python3 harmless.py -c '${code}'` } } }, url, marker)).toBe(false);
  expect(checkedReadiness({ ...part, state: { ...part.state, input: { command: `python3 -O -c '${code}'` } } }, url, marker)).toBe(false);
  expect(checkedReadiness({ ...part, state: { ...part.state, input: { command: `python3 -c 'if False: ${code}'` } } }, url, marker)).toBe(false);
  expect(checkedReadiness({ ...part, state: { ...part.state, input: { command: `python3 -c '${code}'' if False else True'` } } }, url, marker)).toBe(false);
});
