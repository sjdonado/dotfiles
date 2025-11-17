-- Custom Light Theme
-- Based on Neovim's default light theme with modified backgrounds

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') then
  vim.cmd('syntax reset')
end

vim.o.background = 'light'
vim.g.colors_name = 'sjdonado-light'

-- Load default vim colorscheme first
vim.cmd('runtime colors/default.lua')

-- Override specific highlights
vim.api.nvim_set_hl(0, 'Normal', { fg = '#14161B', bg = '#EEF1F8' })
vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = '#E0E2EA' })
vim.api.nvim_set_hl(0, 'WhichKeyBorder', { bg = '#E0E2EA' })
