local auto_dark_mode = require('auto-dark-mode')
local catppuccin = require('catppuccin')
local feline = require('sjdonado.feline')

catppuccin.setup({
  background = {
    light = 'latte',
    dark = 'mocha',
  },
  color_overrides = {
    latte = {
      base = '#ffffff',
    },
  },
  custom_highlights = function(colors)
    return {
      LineNr = { fg = '#898a8c' },
    }
  end
})

auto_dark_mode.setup({
  set_dark_mode = function()
    vim.api.nvim_set_option('background', 'dark')
    feline.setup(require('catppuccin.palettes').get_palette())
  end,
  set_light_mode = function()
    vim.api.nvim_set_option('background', 'light')
    feline.setup(require('catppuccin.palettes').get_palette())
  end,
})

vim.cmd.colorscheme 'catppuccin'

auto_dark_mode.init()
