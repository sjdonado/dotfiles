require("jester").setup({
  cmd = 'npm run test -- --no-coverage -t "$result" -- $file',
  dap = {
    type = "pwa-node",
    request = "launch",
    -- trace = true,
    runtimeArgs = {
      '$path_to_jest',
      '--no-coverage',
      '-t', '$result',
      '--', '$file'
    },
    args = {},
    rootPath = "${workspaceFolder}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    }
  }
})
