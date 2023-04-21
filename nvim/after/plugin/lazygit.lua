local terms = require("toggleterm.terminal")
local Terminal = require("toggleterm.terminal").Terminal

local nnoremap = require("sjdonado.keymap").nnoremap

local lazygit = Terminal:new({
  cmd = "lazygit",
  count = 5,
  direction = "tab",
  on_open = function(term)
    vim.cmd("startinsert!")
  end,
})

function _G.lazygit_toggle()
  lazygit:toggle()
end

nnoremap("<leader>g", "<cmd>lua lazygit_toggle()<CR>")
