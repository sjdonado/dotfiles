local nnoremap = require('sjdonado.keymap').nnoremap
local dapui = require('sjdonado.dap').dapui

require('toggleterm').setup({
  size = 25,
})

nnoremap('<leader>;', function()
  dapui.close()
  vim.cmd(':ToggleTerm<CR>')
end)

nnoremap('<leader>1;', function()
  vim.cmd(':1ToggleTerm<CR>')
end)

nnoremap('<leader>2;', function()
  vim.cmd(':2ToggleTerm<CR>')
end)

nnoremap('<leader>3;', function()
  dapui.close()
  vim.cmd('ToggleTermToggleAll')
end)


function _G.set_terminal_keymaps()
  local opts = {buffer = 0}
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
