-- Custom Light Theme
-- Based on Neovim's default light theme with modified backgrounds

vim.o.background = 'light'
vim.g.colors_name = 'sjdonado-light'

-- Load default vim colorscheme first
vim.cmd 'runtime colors/default.lua'

-- Override specific highlights
vim.api.nvim_set_hl(0, 'Normal', { fg = '#14161B', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NormalNC', { fg = '#14161B', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'LineNr', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'FoldColumn', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#E0E2EA' }) -- Match WhichKeyNormal bg
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = '#E0E2EA' })
vim.api.nvim_set_hl(0, 'WhichKeyBorder', { bg = '#E0E2EA' })
vim.api.nvim_set_hl(0, 'GitSignsCurrentLineBlame', { fg = '#6B7280', italic = true }) -- Darker gray for better readability on cursor line
