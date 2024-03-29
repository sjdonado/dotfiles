local Path = require("plenary.path")

local jester = require("jester")
local file_helper = require("sjdonado.helpers.file")

function _G.create_jester_terminal()
  local jester_term_actions = require("sjdonado.toggleterm").create_terminal({
    direction = "float",
    keymap = "<leader>jt",
    count = 99,
    start_in_insert = false,
  })

  jester_term_actions.toggle()
end

local default = {
  identifiers = { "test", "it" }, -- used to identify tests
  prepend = { "describe" }, -- prepend describe blocks
  expressions = { "call_expression" }, -- tree-sitter object used to scan for tests/describe blocks
  terminal_cmd = "lua create_jester_terminal()",
  escapeRegex = false,
  regexStartEnd = false,
  dap = {
    type = "pwa-node",
    request = "launch",
    -- trace = true,
    program = "$path_to_jest",
    cwd = "${workspaceFolder}",
    skipFiles = { "<node_internals>/**/*.js" },
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
    disableOptimisticBPs = true,
  },
}

local function load_jest()
  jester.setup(vim.tbl_extend("force", default, {
    path_to_jest_run = " npm run test -- --watch=false --no-coverage", -- space at the beginning == private command
    path_to_jest_debug = "./node_modules/.bin/jest",
    escapeRegex = true,
    regexStartEnd = true,
    dap = vim.tbl_extend("force", default.dap, {
      args = {
        "--watch",
        "false",
        "--testNamePattern",
        "${jest.testNamePattern}",
        "--runTestsByPath",
        "${jest.testFile}",
      },
    }),
  }))
end

local function load_bun_test()
  jester.setup(vim.tbl_extend("force", default, {
    path_to_jest_run = "bun test",
    path_to_jest_debug = "bun test",
    run_cmd = " bun test -t '$result$' $file",
    run_file_cmd = " bun test $file",
    escapeRegex = false,
    regexStartEnd = false,
    dap = vim.tbl_extend("force", default.dap, {
      args = {
        "--watch",
        "false",
        "--testNamePattern",
        "${jest.testNamePattern}",
      },
    }),
  }))
end

local function load_vitest()
  local relative_path = Path:new(vim.api.nvim_buf_get_name(0)):make_relative(vim.loop.cwd())
  jester.setup(vim.tbl_extend("force", default, {
    path_to_jest_run = "vitest",
    path_to_jest_debug = "./node_modules/.bin/vitest",
    run_cmd = " npm run test -- --watch=false --no-coverage -t '$result' " .. relative_path,
    dap = vim.tbl_extend("force", default.dap, {
      args = {
        "--watch",
        "false",
        "--testNamePattern",
        "${jest.testNamePattern}",
        relative_path,
      },
    }),
  }))
end

local function load_playwright()
  local relative_path = Path:new(vim.api.nvim_buf_get_name(0)):make_relative(vim.loop.cwd())
  jester.setup(vim.tbl_extend("force", default, {
    path_to_jest_debug = "./node_modules/.bin/playwright test",
    run_cmd = " npm run test -- -g '$result' " .. relative_path,
    run_file_cmd = " npm run test '$file'",
    dap = nil,
  }))
end

vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = function()
    if file_helper.root_has_file("*vitest*") or vim.fn.search("vitest", "nw") ~= 0 then
      load_vitest()
    end
    if file_helper.root_has_file("*jest*") or vim.fn.search("jest", "nw") ~= 0 then
      load_jest()
    end
    if file_helper.root_has_file("bun.lockb") or vim.fn.search("jest", "nw") ~= 0 then
      load_bun_test()
    end
    if
      file_helper.root_has_file("playwright.config*") or vim.fn.search("playwright", "nw") ~= 0
    then
      load_playwright()
    end
  end,
})
