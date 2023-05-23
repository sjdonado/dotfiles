local dap = require("dap")

require("dap").adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter",
    args = { "${port}" },
  }
}

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
