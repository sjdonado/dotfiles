local auto_dark_mode = require('auto-dark-mode')
local github_theme = require('github-theme')

local statusline = require('sjdonado.feline')
local treesitter_context = require('sjdonado.treesitter-context')

github_theme.setup({
  colors = {
    line_nr = '#898a8c',
  },
})

auto_dark_mode.setup({
	set_dark_mode = function()
		vim.api.nvim_set_option('background', 'dark')
		vim.cmd('colorscheme github_dark')
    statusline.dark_setup()
	end,
	set_light_mode = function()
		vim.api.nvim_set_option('background', 'light')
		vim.cmd('colorscheme github_light')
    statusline.light_setup()
	end,
})

auto_dark_mode.init()

treesitter_context.setup(true)
