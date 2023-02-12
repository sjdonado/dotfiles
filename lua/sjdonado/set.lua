vim.api.nvim_exec("language en_US", true)

vim.opt.guicursor = ""
vim.opt.mouse = ""

vim.opt.termguicolors = true

vim.g.mapleader = " "

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.list = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.expandtab = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.smartindent = true
vim.opt.wrap = false

-- Keep cursorline vertically centered
vim.opt.scrolloff = 999

-- Treesitter fold config
vim.opt.foldlevel = 20
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- only one shared statusline at the bottom
vim.opt.laststatus = 3

-- open new splits on the right
vim.opt.splitright = true

-- hide tabline
vim.opt.showtabline = 0

-- runtime path macos fix
vim.o.runtimepath = vim.fn.stdpath("data") .. "/site/pack/*/start/*," .. vim.o.runtimepath
