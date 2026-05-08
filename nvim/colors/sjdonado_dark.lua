-- Custom Dark Theme
-- Based on Neovim's default dark theme with modified backgrounds

vim.o.background = 'dark'

-- Load default vim colorscheme first (this sets colors_name = 'default')
vim.cmd 'runtime colors/default.lua'

-- Reclaim the name after default.lua overwrites it
vim.g.colors_name = 'sjdonado_dark'

local function apply_highlights()
  vim.api.nvim_set_hl(0, 'Normal', { fg = '#E0E2EA', bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'NormalNC', { fg = '#E0E2EA', bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'SignColumn', { bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'LineNr', { bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'FoldColumn', { bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#14161B' })
  vim.api.nvim_set_hl(0, 'FloatBorder', { bg = '#07080d' })
  vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = '#14161B' })
  vim.api.nvim_set_hl(0, 'WhichKeyBorder', { bg = '#14161B' })
  vim.api.nvim_set_hl(0, 'GitSignsCurrentLineBlame', { fg = '#9CA3AF', italic = true })
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
end

-- Re-apply on every ColorScheme event so plugins reloading the scheme can't strip overrides
local group = vim.api.nvim_create_augroup('SjdonadoDark', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  pattern = 'sjdonado_dark',
  callback = apply_highlights,
})

apply_highlights()
