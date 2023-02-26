local auto_dark_mode = require("auto-dark-mode")

local githubtheme = require("github-theme")
local U = require("github-theme.util")

local lualine = require("sjdonado.lualine")

githubtheme.setup({
	dark_float = true,
	overrides = function(c)
		return {
			LineNr = { fg = U.lighten(c.line_nr, 0.4) },
			TreesitterContext = { bg = U.darken(c.blue, 0.2) },
		}
	end,
})

auto_dark_mode.setup({
	set_dark_mode = function()
		vim.api.nvim_set_option("background", "dark")
		vim.cmd("colorscheme github_dark")
		lualine.load()
	end,
	set_light_mode = function()
		vim.api.nvim_set_option("background", "light")
		vim.cmd("colorscheme github_light")
		lualine.load()
	end,
})

-- Hide CursorLine on leave window (ignore Floating windows)
vim.cmd("autocmd WinEnter *.*,*.git/* setlocal cursorline")
vim.cmd("autocmd WinLeave *.*,*.git/* setlocal nocursorline")

auto_dark_mode.init()
