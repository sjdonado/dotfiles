local Terminal = require("toggleterm.terminal").Terminal

local nnoremap = require("sjdonado.keymap").nnoremap
local tnoremap = require("sjdonado.keymap").tnoremap

local lazygit = Terminal:new({
  cmd = "lazygit",
  count = 100,
  direction = "tab",
  on_open = function(term)
    vim.cmd("startinsert")
    tnoremap("<C-c>", "<C-\\><C-n>", { buffer = term.bufnr, silent = true })
  end,
})

nnoremap("<C-g>", function()
  lazygit:toggle()
end)
