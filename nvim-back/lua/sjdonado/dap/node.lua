local dap = require("dap")

require("dap").adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter",
    args = { "${port}" },
  },
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
    name = "Launch (npm command)",
    type = "pwa-node",
    request = "launch",
    runtimeExecutable = "npm",
    runtimeArgs = {
      "run",
      "debug",
    },
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
    cwd = "${workspaceFolder}/src",
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
    -- protocol = "inspector",
    -- console = "integratedTerminal",
    processId = require("dap.utils").pick_process,
    -- restart = true,
    -- smartStep = true,
    port = 8999,
    -- timeout = 20000,
  },
}
