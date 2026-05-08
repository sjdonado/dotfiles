-- Custom Light Theme
-- Based on Neovim's default light theme with modified backgrounds

vim.o.background = 'light'

-- Load default vim colorscheme first (this sets colors_name = 'default')
vim.cmd 'runtime colors/default.lua'

-- Reclaim the name after default.lua overwrites it
vim.g.colors_name = 'sjdonado_light'

local function apply_highlights()
  vim.api.nvim_set_hl(0, 'Normal', { fg = '#14161B', bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'NormalNC', { fg = '#14161B', bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'SignColumn', { bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'LineNr', { bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'FoldColumn', { bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#E0E2EA' })
  vim.api.nvim_set_hl(0, 'FloatBorder', { bg = '#EEF1F8' })
  vim.api.nvim_set_hl(0, 'WhichKeyNormal', { bg = '#E0E2EA' })
  vim.api.nvim_set_hl(0, 'WhichKeyBorder', { bg = '#E0E2EA' })
  vim.api.nvim_set_hl(0, 'GitSignsCurrentLineBlame', { fg = '#6B7280', italic = true })
end

local group = vim.api.nvim_create_augroup('SjdonadoLight', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  pattern = 'sjdonado_light',
  callback = apply_highlights,
})

apply_highlights()
