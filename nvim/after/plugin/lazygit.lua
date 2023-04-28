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

nnoremap("<leader>g", function()
  lazygit:toggle()
end)
