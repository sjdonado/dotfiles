local auto_dark_mode = require('auto-dark-mode')

local githubtheme = require('github-theme')
local C = require('github-theme.colors')
local U = require('github-theme.util')

local feline = require('sjdonado.feline')

githubtheme.setup({
  theme_style = vim.o.background == 'dark' and 'dark' or 'light',
  dark_float = true,
  overrides = function(c)
    return {
      LineNr = { fg = U.lighten(c.line_nr, 0.4) },
      TreesitterContext = { bg = U.darken(c.blue, 0.2) },
    }
  end
})

local statusline_dark = C.setup({ theme_style = 'dark' })
local statusline_light = C.setup({ theme_style = 'light' })

auto_dark_mode.setup({
  set_dark_mode = function()
    vim.api.nvim_set_option('background', 'dark')
    vim.cmd('colorscheme github_dark')
    feline.setup(statusline_dark)
  end,
  set_light_mode = function()
    vim.api.nvim_set_option('background', 'light')
    vim.cmd('colorscheme github_light')
    feline.setup(statusline_light)
  end,
})

auto_dark_mode.init()
