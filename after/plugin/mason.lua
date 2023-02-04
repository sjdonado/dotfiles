local mason = require('mason')
local masontoolinstaller = require('mason-tool-installer')

mason.setup({
  ui = {
    border = 'double',
  }
})

masontoolinstaller.setup({
  ensure_installed = {
    'typescript-language-server',
    'eslint-lsp',
    'js-debug-adapter',
    'yaml-language-server',
    'gopls',
    'staticcheck',
    'delve',
  },
  run_on_start = false,
})

