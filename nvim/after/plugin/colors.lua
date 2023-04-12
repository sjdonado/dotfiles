local githubtheme = require("github-theme")

local lualine = require("sjdonado.lualine")

githubtheme.setup({
  sidebars = { "nvim-tree", "terminal", "packer", "mason" },
  darkSidebar = true,
})

-- Hide CursorLine on leave window (ignore Floating windows)
vim.cmd("autocmd WinEnter *.*,*.git/* setlocal cursorline")
vim.cmd("autocmd WinLeave *.*,*.git/* setlocal nocursorline")

vim.cmd("colorscheme github_dark_default")
lualine.load()
