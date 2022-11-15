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
  },
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach",
    processId = require'dap.utils'.pick_process,
    cwd = "${workspaceFolder}",
  },
  {
    type = "pwa-node",
    request = "launch",
    name = "Debug Jest Tests",
    -- trace = true, -- include debugger info
    runtimeExecutable = "node",
    runtimeArgs = {
      "./node_modules/jest/bin/jest.js",
      "--runInBand",
    },
    rootPath = "${workspaceFolder}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
  }
}

