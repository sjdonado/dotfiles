local mason = require("mason")
local masontoolinstaller = require("mason-tool-installer")

mason.setup({
  ui = {
    border = "rounded",
  },
})

masontoolinstaller.setup({
  ensure_installed = {
    "cpplint",
    "css-lsp",
    "delve",
    "eslint_d",
    "fixjson",
    "gopls",
    "js-debug-adapter",
    "lua-language-server",
    "prettierd",
    "python-lsp-server",
    "rust-analyzer",
    "ruff",
    "staticcheck",
    "stylua",
    "taplo",
    "typescript-language-server",
    "yaml-language-server",
  },
  run_on_start = false,
})
