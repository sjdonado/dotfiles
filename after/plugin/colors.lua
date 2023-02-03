local auto_dark_mode = require('auto-dark-mode')

local githubtheme = require('github-theme')
local C = require('github-theme.colors')
local U = require('github-theme.util')

local feline = require('sjdonado.feline')

githubtheme.setup({
  dark_float = true,
  colors = {
    line_nr = '#898a8c',
  },
  overrides = function(c)
    return {
      TreesitterContext = { bg = U.darken(c.blue, 0.2) },
    }
  end
})

auto_dark_mode.setup({
  set_dark_mode = function()
    vim.api.nvim_set_option('background', 'dark')
    vim.cmd('colorscheme github_dark')
    feline.setup(C.setup({ theme_style = 'dark' }))
  end,
  set_light_mode = function()
    vim.api.nvim_set_option('background', 'light')
    vim.cmd('colorscheme github_light')
    feline.setup(C.setup({ theme_style = 'light' }))
  end,
})

auto_dark_mode.init()
