-- Custom Dark Theme
-- Based on Neovim's default dark theme with modified backgrounds

vim.o.background = 'dark'
vim.g.colors_name = 'sjdonado-dark'

-- Load default vim colorscheme first
vim.cmd 'runtime colors/default.lua'

-- Override specific highlights
vim.api.nvim_set_hl(0, 'Normal', { fg = '#E0E2EA', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NormalNC', { fg = '#E0E2EA', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'LineNr', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'FoldColumn', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#14161B' }) -- Match WhichKeyNormal bg
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'NONE' })
vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = '#14161B' })
vim.api.nvim_set_hl(0, 'WhichKeyBorder', { bg = '#14161B' })
vim.api.nvim_set_hl(0, 'GitSignsCurrentLineBlame', { fg = '#9CA3AF', italic = true }) -- Lighter gray for better readability on cursor line
vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal', { fg = '#E0E2EA', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatuslineModeInsert', { fg = '#E0E2EA', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatuslineModeVisual', { fg = '#E0E2EA', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatuslineModeReplace', { fg = '#E0E2EA', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatuslineModeCommand', { fg = '#E0E2EA', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatuslineModeOther', { fg = '#E0E2EA', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = '#9CA3AF', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = '#E0E2EA', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = '#9CA3AF', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'MiniStatuslineInactive', { fg = '#6B7280', bg = 'NONE' })
