local dap = require('dap')

require('dap-vscode-js').setup({
  debugger_path = vim.fn.stdpath('data') .. '/mason/packages/js-debug-adapter',
  debugger_cmd = { 'js-debug-adapter' },
  adapters = { 'pwa-node' },
})

dap.configurations.javascript = {
  {
    name = 'Launch (getir)',
    type = 'pwa-node',
    request = 'launch',
    program = '${workspaceFolder}/bin',
    rootPath = '${workspaceFolder}',
    cwd = '${workspaceFolder}',
    skipFiles = {
      '<node_internals>/**',
    },
    resolveSourceMapLocations = {
      '${workspaceFolder}/**',
      '!**/node_modules/**',
    },
    protocol = 'inspector',
    console = 'integratedTerminal',
  },
  {
    name = 'Attach to node process',
    type = 'pwa-node',
    request = 'attach',
    cwd = '${workspaceFolder}',
    processId = require('dap.utils').pick_process,
  },
}
