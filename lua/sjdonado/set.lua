vim.opt.guicursor = ""
vim.opt.mouse = ""

vim.opt.termguicolors = true

vim.g.mapleader = " "

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.expandtab = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.smartindent = true
vim.opt.wrap = false

-- a single statusline at the bottom
vim.opt.laststatus = 3

-- open new splits on the right
vim.opt.splitright = true

-- macos fix
vim.o.runtimepath = vim.fn.stdpath('data') .. '/site/pack/*/start/*,' .. vim.o.runtimepath

-- nvim tree config
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
