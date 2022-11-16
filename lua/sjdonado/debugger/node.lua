local dap = require('dap')

require("dap-vscode-js").setup({
  adapters = { 'pwa-node' },
})

dap.configurations.javascript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch (getir)",
    program = "${workspaceFolder}/bin",
    rootPath = "${workspaceFolder}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    skipFiles = {
      "<node_internals>/**",
    },
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    }
  },
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach",
    processId = require'dap.utils'.pick_process,
    cwd = "${workspaceFolder}",
  },
}
