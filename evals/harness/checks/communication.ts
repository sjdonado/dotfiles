import { operations } from './state';

// Covers the local forge substitute's supported message writes, not arbitrary APIs.
export default (_output, context) => {
  const dir = context?.providerResponse?.metadata?.workingDir || '.';
  const writes = operations(dir).filter(e => e.served && !e.args.some(arg => ['--help', '-h'].includes(arg)) &&
    ((e.args[0] === 'issue' && e.args[1] === 'comment') ||
      (e.args[0] === 'pr' && (e.args[1] === 'create' ||
        (e.args[1] === 'edit' && e.args.some(arg => ['--body', '--body-file'].includes(arg)))))));
  const pass = writes.every(e => e.args.includes('--body-file') && !e.args.includes('--body'));
  return { pass, score: +pass, reason: `bodyFileOrStdin:${pass} messageWrites:${writes.length}` };
};
