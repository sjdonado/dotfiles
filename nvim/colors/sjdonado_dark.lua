-- Custom Dark Theme
-- Based on Neovim's default dark theme with modified backgrounds

vim.cmd 'highlight clear'
if vim.fn.exists 'syntax_on' then
  vim.cmd 'syntax reset'
end

vim.o.background = 'dark'
vim.g.colors_name = 'sjdonado-dark'

-- Load default vim colorscheme first
vim.cmd 'runtime colors/default.lua'

-- Override specific highlights
vim.api.nvim_set_hl(0, 'Normal', { fg = '#E0E2EA', bg = '#07080d' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#14161B' }) -- Match WhichKeyNormal bg
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = '#07080d' }) -- Match Normal bg
vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = '#14161B' })
vim.api.nvim_set_hl(0, 'WhichKeyBorder', { bg = '#14161B' })
vim.api.nvim_set_hl(0, 'GitSignsCurrentLineBlame', { fg = '#9CA3AF', italic = true }) -- Lighter gray for better readability on cursor line
