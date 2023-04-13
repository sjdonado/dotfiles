local vscode = require("vscode")
local lualine = require("sjdonado.lualine")

-- Hide CursorLine on leave window (ignore Floating windows)
vim.cmd("autocmd WinEnter *.*,*.git/* setlocal cursorline")
vim.cmd("autocmd WinLeave *.*,*.git/* setlocal nocursorline")

vscode.load()
lualine.load()
