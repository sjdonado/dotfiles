local dap = require("dap")

require("dap-vscode-js").setup({
  debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
  debugger_cmd = { "js-debug-adapter" },
  adapters = { "pwa-node" },
})

dap.configurations.javascript = {
  {
    name = "Launch",
    type = "pwa-node",
    request = "launch",
    -- trace = true,
    program = "${workspaceFolder}/bin",
    cwd = "${workspaceFolder}",
    rootPath = "${workspaceFolder}",
    skipFiles = { "<node_internals>/**/*.js" },
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
    protocol = "inspector",
    console = "integratedTerminal",
  },
  {
    name = "Attach To Process",
    type = "pwa-node",
    request = "attach",
    cwd = "${workspaceFolder}",
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
    processId = require("dap.utils").pick_process,
  },
}
