local githubtheme = require("github-theme")

local lualine = require("sjdonado.lualine")

githubtheme.setup({
  dark_float = true,
})

-- Hide CursorLine on leave window (ignore Floating windows)
vim.cmd("autocmd WinEnter *.*,*.git/* setlocal cursorline")
vim.cmd("autocmd WinLeave *.*,*.git/* setlocal nocursorline")

vim.api.nvim_set_option("background", "dark")
vim.cmd("colorscheme github_dark")
lualine.load()
